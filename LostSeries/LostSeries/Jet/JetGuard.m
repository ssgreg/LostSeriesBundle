//
//  JetGuard.m
//  LostSeries
//
//  Created by Grigory Zubankov on 06/05/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Jet
#import "JetGuard.h"


//
// JetGuard
//

@implementation JetGuard
{
  BOOL theFlagIsLocked;
}

+ (JetGuard*) guard
{
  return [[JetGuard alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theFlagIsLocked = NO;
  //
  return self;
}

- (BOOL) lock
{
  BOOL flagWasLocked = self.locked;
  theFlagIsLocked = YES;
  return !flagWasLocked;
}

- (void) unlock
{
  theFlagIsLocked = NO;
}

- (BOOL) locked
{
  return theFlagIsLocked;
}

@end
