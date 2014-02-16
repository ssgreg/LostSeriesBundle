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
  [theNextWL internalInput];
}

- (void) forwardBlock
{
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

- (void) internalInput
{
  NSLog(@"WLInput - %@", NSStringFromClass([self class]));
  self.isBlocked = NO;
  [self input];
}

- (void) internalBlock
{
  NSLog(@"WLBLock - %@", NSStringFromClass([self class]));
  self.isBlocked = YES;
  [self block];
  [self forwardBlock];
}

@end



//
// WFWorkflow
//

@implementation WFWorkflow
{
  WFWorkflowLink* theWLinkFirst;
  WFWorkflowLink* theWLinkLast;
}

- (id) initWithFirstWLink:(WFWorkflowLink*)wLinkFirst lastWLink:(WFWorkflowLink*)wLinkLast
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theWLinkFirst = wLinkFirst;
  theWLinkLast = wLinkLast;
  //
  __weak typeof(self) weakSelf = self;
  void(^outputHandler)() = ^()
  {
    [weakSelf output];
  };
  void(^forwardBlockHandler)() = ^()
  {
    [weakSelf forwardBlock];
  };
  WFForwardWorkflowLink* wLinkForward = [[WFForwardWorkflowLink alloc] initWithOutputHandler:outputHandler forwardBlockHandler:forwardBlockHandler];
  //
  wLinkLast.nextLink = wLinkForward;
  //
  return self;
}

- (void) input
{
  [theWLinkFirst internalInput];
}

- (void) block
{
  [theWLinkLast forwardBlock];
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

@end


//
// WFWorkflowBatchUsingAnd
//

@implementation WFWorkflowBatchUsingAnd
{
  NSArray* theWLs;
  NSMutableDictionary* theReplies;
  BOOL theBlockBlockFlag;
}

- (id) initWithArray:(NSArray*)wls
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theReplies = [NSMutableDictionary dictionary];
  theWLs = wls;
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
  theReplies[[NSNumber numberWithLongLong:(uintptr_t)wl]] = @YES;
  if (theReplies.count == theWLs.count)
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
  return [[WFWorkflow alloc] initWithFirstWLink:wl lastWLink:curWL];
}

WFWorkflowLink* WFLinkWorkflowBatchUsingAnd(WFWorkflowLink* wl, ...)
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
  return [[WFWorkflowBatchUsingAnd alloc] initWithArray:wls];
}
