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

@interface WFWorkflowLink ()
{
  __weak id theData;
  __weak id theView;
  //
  void (^theOutputHandler)();
  void (^theForwardBlockHandler)();
  void (^theNextLinkHandler)();
}

- (void) setNextLinkHandler:(void (^)())handler;
- (void) nextLink;

@end

@implementation WFWorkflowLink

- (id) initWithData:(id)data view:(id)view
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theData = data;
  theView = view;
  return self;
}

- (id) initWithData:(id)data
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theData = data;
  return self;
}

- (id) initWithView:(id)view
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theView = view;  return self;
}

- (id) workflowData
{
  return theData;
}

- (id) workflowView
{
  return theView;
}

- (void) setOutputHandler:(void (^)())handler
{
  theOutputHandler = handler;
}

- (void) setForwardBlockHandler:(void (^)())handler
{
  theForwardBlockHandler = handler;
}

- (void) setNextLinkHandler:(void (^)())handler
{
  theNextLinkHandler = handler;
}

- (void) nextLink
{
  if (theNextLinkHandler)
  {
    theNextLinkHandler();
  }
}

- (void) output
{
  if (theOutputHandler)
  {
    theOutputHandler();
  }
}

- (void) forwardBlock
{
  if (theForwardBlockHandler)
  {
    theForwardBlockHandler();
  }
}

- (void) input
{
}

- (void) block
{
}

- (void) update
{
}

@end


//
// WFWorkflow
//

@interface WFWorkflow ()
{
  __weak WFWorkflowLink<WFWorkflowLinkProtocol>* theInitialLink;
  __weak WFWorkflowLink<WFWorkflowLinkProtocol>* theLastLink;
}
@end

@implementation WFWorkflow

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  return self;
}

- (WFWorkflow*) link:(WFWorkflowLink<WFWorkflowLinkProtocol>*) link
{
  if (!theInitialLink)
  {
    theInitialLink = link;
  }
  else
  {
    __weak WFWorkflowLink<WFWorkflowLinkProtocol>* weakLink = link;
    [theLastLink setOutputHandler: ^()
    {
      [weakLink input];
    }];
    [theLastLink setForwardBlockHandler: ^()
    {
      [weakLink block];
      [weakLink nextLink];
    }];
    [theLastLink setForwardBlockHandler: ^()
    {
      [weakLink block];
      [weakLink nextLink];
    }];
  }
  [link update];
  theLastLink = link;
  return self;
}

- (void) start
{
  [theInitialLink input];
}

@end
