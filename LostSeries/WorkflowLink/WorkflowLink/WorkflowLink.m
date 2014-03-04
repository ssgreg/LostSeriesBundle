//
//  WorkflowLink.m
//  WorkflowLink
//
//  Created by Grigory Zubankov on 07/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "WorkflowLink.h"


//
// WFWorkflowLink
//

@implementation WFWorkflowLink
{
  __weak id theData;
  __weak id theView;
  BOOL theIsBlockedFlag;
  //
  WFWorkflowLink* theNextWL;
}

@synthesize isBlocked = theIsBlockedFlag;

- (void) internalInitWithData:(id)data view:(id)view
{
  theData = data;
  theView = view;
  self.isBlocked = YES;
  [self update];
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  [self internalInitWithData:nil view:nil];
  return self;
}

- (id) initWithData:(id)data view:(id)view
{
  if (!(self = [super init]))
  {
    return nil;
  }
  [self internalInitWithData:data view:view];
  return self;
}

- (id) initWithData:(id)data
{
  if (!(self = [super init]))
  {
    return nil;
  }
  [self internalInitWithData:data view:nil];
  return self;
}

- (id) initWithView:(id)view
{
  if (!(self = [super init]))
  {
    return nil;
  }
  [self internalInitWithData:nil view:view];
  return self;
}

- (id) workflowData
{
  return theData;
}

- (id) workflowView
{
  return theView;
}

- (WFWorkflowLink*) nextLink
{
  return theNextWL;
}

- (void) setNextLink:(WFWorkflowLink *)nextLink
{
  theNextWL = nextLink;
}

- (void) output
{
  if (self.needLog)
  {
    NSLog(@"WLOutput - %@", NSStringFromClass([self class]));
  }
  [theNextWL internalInput];
}

- (void) forwardBlock
{
  if (self.needLog)
  {
    NSLog(@"WLForwardBlock - %@", NSStringFromClass([self class]));
  }
  [theNextWL internalBlock];
}

- (void) input
{
  [self output];
}

- (void) block
{
}

- (void) update
{
}

- (BOOL) needLog
{
  return YES;
}

- (void) internalInput
{
  if (self.needLog)
  {
    NSLog(@"WLInput - %@", NSStringFromClass([self class]));
  }
  self.isBlocked = NO;
  [self input];
}

- (void) internalBlock
{
  if (self.needLog)
  {
    NSLog(@"WLBLock - %@", NSStringFromClass([self class]));
  }
  self.isBlocked = YES;
  [self block];
  [self forwardBlock];
}

@end



//
// WFWorkflowBatch
//

@implementation WFWorkflowBatch
{
  WFWorkflowLink* theWLinkFirst;
  WFWorkflowLink* theWLinkLast;
  BOOL theFlagMakeRing;
}

- (void) initInternal:(WFWorkflowLink*)wLinkFirst lastWLink:(WFWorkflowLink*)wLinkLast makeRing:(BOOL)flagMakeRing
{
  theWLinkFirst = wLinkFirst;
  theWLinkLast = wLinkLast;
  theWLinkLast.nextLink = WFLinkToSelfForward(self);
  theFlagMakeRing = flagMakeRing;
}

- (id) initWithFirstWLink:(WFWorkflowLink*)wLinkFirst lastWLink:(WFWorkflowLink*)wLinkLast
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  [self initInternal:wLinkFirst lastWLink:wLinkLast makeRing:NO];
  //
  return self;
}

- (id) initRingWithFirstWLink:(WFWorkflowLink*)wLinkFirst lastWLink:(WFWorkflowLink*)wLinkLast
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  [self initInternal:wLinkFirst lastWLink:wLinkLast makeRing:YES];
  //
  return self;
}

- (void) input
{
  [theWLinkFirst internalInput];
}

- (void) block
{
  [theWLinkFirst forwardBlock];
}

- (BOOL) needLog
{
  return NO;
}

- (void) output
{
  [super output];
  if (theFlagMakeRing)
  {
    [self input];
  }
}

@end


//
// WFForwardWorkflowLink
//

@implementation WFForwardWorkflowLink
{
  void (^theOutputHandler)();
  void (^theForwardBlockHandler)();
}

- (id) initWithOutputHandler:(void (^)())outputHandler forwardBlockHandler:(void (^)())forwardBlockHandler;
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theOutputHandler = outputHandler;
  theForwardBlockHandler = forwardBlockHandler;
  return self;
}

- (void) input
{
  theOutputHandler(self);
}

- (void) block
{
  theForwardBlockHandler(self);
}

- (BOOL) needLog
{
  return NO;
}

@end


//
// WFWorkflowBatchWithOutputCondition
//

@implementation WFWorkflowBatchWithOutputCondition
{
  NSArray* theWLs;
  BOOL(^theOutputCondition)(NSArray*wls, WFWorkflowLink* wl);
  BOOL theBlockBlockFlag;
}

- (id) initWithArray:(NSArray*)wls outputCodition:(BOOL(^)(NSArray*wls, WFWorkflowLink* wl))condition
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theWLs = wls;
  theOutputCondition = condition;
  //
  for (WFWorkflowLink* wl in wls)
  {
    [self link:wl];
  }
  //
  return self;
}

- (void) input
{
  theBlockBlockFlag = NO;
  for (WFWorkflowLink* wl in theWLs)
  {
    [wl internalInput];
  }
}

- (void) block
{
  for (WFWorkflowLink* wl in theWLs)
  {
    [wl internalBlock];
  }
}

- (void) commonOutput:(WFWorkflowLink*)wl
{
  if (theOutputCondition(theWLs, wl))
  {
    [self output];
  }
}

- (void) commonBlock
{
  if (!theBlockBlockFlag)
  {
    [self forwardBlock];
  }
  theBlockBlockFlag = YES;
}

- (void) link:(WFWorkflowLink*)wl
{
  __weak typeof(self) weakSelf = self;
  void(^outputHandler)() = ^()
  {
    [weakSelf commonOutput:wl];
  };
  void(^forwardBlockHandler)() = ^()
  {
    [weakSelf commonBlock];
  };
  WFForwardWorkflowLink* wlForward = [[WFForwardWorkflowLink alloc] initWithOutputHandler:outputHandler forwardBlockHandler:forwardBlockHandler];
  wl.nextLink = wlForward;
}

@end


//
// WFWorkflowSplitterWithOutputUsingAnd
//

@implementation WFWorkflowSplitterWithOutputUsingAnd
{
  NSMutableDictionary* theReplies;
}

- (id) initWithArray:(NSArray*)wls
{
  self = [super initWithArray:wls outputCodition:^BOOL(NSArray* wls, WFWorkflowLink* wl)
  {
    theReplies[[NSNumber numberWithLongLong:(uintptr_t)wl]] = @YES;
    if (theReplies.count == wls.count)
    {
      [theReplies removeAllObjects];
      return YES;
    }
    return NO;
  }];
  if (self)
  {
    theReplies = [NSMutableDictionary dictionary];
  }
  return self;
}

@end


//
// WFWorkflowSplitterWithOutputUsingOr
//

@implementation WFWorkflowSplitterWithOutputUsingOr

- (id) initWithArray:(NSArray*)wls
{
  return [super initWithArray:wls outputCodition:^BOOL(NSArray* wls, WFWorkflowLink* wl)
  {
    return YES;
  }];
}

@end


WFWorkflow* WFLinkWorkflow(WFWorkflowLink* wl, ...)
{
  va_list args;
  va_start(args, wl);
  //
  WFWorkflowLink* nextWL = nil;
  WFWorkflowLink* curWL = wl;
  while ((nextWL = va_arg(args, WFWorkflowLink*)))
  {
    curWL.nextLink = nextWL;
    curWL = nextWL;
  }
  //
  va_end(args);
  return [[WFWorkflowBatch alloc] initWithFirstWLink:wl lastWLink:curWL];
}


WFWorkflow* WFLinkRingWorkflow(WFWorkflowLink* wl, ...)
{
  va_list args;
  va_start(args, wl);
  //
  WFWorkflowLink* nextWL = nil;
  WFWorkflowLink* curWL = wl;
  while ((nextWL = va_arg(args, WFWorkflowLink*)))
  {
    curWL.nextLink = nextWL;
    curWL = nextWL;
  }
  //
  va_end(args);
  return [[WFWorkflowBatch alloc] initRingWithFirstWLink:wl lastWLink:curWL];
}


WFWorkflow* WFSplitWorkflowWithOutputUsingAnd(WFWorkflowLink* wl, ...)
{
  va_list args;
  va_start(args, wl);
  //
  NSMutableArray* wls = [NSMutableArray array];
  for (WFWorkflowLink* nextWL = wl; nextWL; nextWL = va_arg(args, WFWorkflowLink*))
  {
    [wls addObject:nextWL];
  }
  //
  va_end(args);
  return [[WFWorkflowSplitterWithOutputUsingAnd alloc] initWithArray:wls];
}


WFWorkflow* WFSplitWorkflowWithOutputUsingOr(WFWorkflowLink* wl, ...)
{
  va_list args;
  va_start(args, wl);
  //
  NSMutableArray* wls = [NSMutableArray array];
  for (WFWorkflowLink* nextWL = wl; nextWL; nextWL = va_arg(args, WFWorkflowLink*))
  {
    [wls addObject:nextWL];
  }
  //
  va_end(args);
  return [[WFWorkflowSplitterWithOutputUsingOr alloc] initWithArray:wls];
}


WFWorkflow* WFLinkToSelfForward(WFWorkflowLink* wlSelf)
{
  __weak WFWorkflowLink* weakSelf = wlSelf;
  void(^outputHandler)() = ^()
  {
    [weakSelf output];
  };
  void(^forwardBlockHandler)() = ^()
  {
    [weakSelf forwardBlock];
  };
  return [[WFForwardWorkflowLink alloc] initWithOutputHandler:outputHandler forwardBlockHandler:forwardBlockHandler];
}
