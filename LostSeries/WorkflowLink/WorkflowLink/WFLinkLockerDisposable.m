//
//  WFLinkLockerDisposable.m
//  WorkflowLink
//
//  Created by Grigory Zubankov on 06/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// WF
#import "WFLinkLockerDisposable.h"


//
// WFLinkLockerDisposable
//


@implementation WFLinkLockerDisposable
{
  BOOL theIsLockedFlag;
}

- (void) use
{
  theIsLockedFlag = NO;
  [self input];
}

- (void) update
{
  theIsLockedFlag = YES;
}

- (void) input
{
  if (theIsLockedFlag)
  {
    [self forwardBlock];
  }
  else
  {
    [self output];
  }
}

@end
