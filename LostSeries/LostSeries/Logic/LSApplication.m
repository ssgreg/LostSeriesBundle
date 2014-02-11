//
//  LSApplication.m
//  LostSeries
//
//  Created by Grigory Zubankov on 10/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Logic
#import "LSApplication.h"


//
// LSApplication
//

@interface LSApplication ()
{
  NSString* theDeviceToken;
}
@end

@implementation LSApplication

@synthesize deviceToken = theDeviceToken;

+ (LSApplication*) singleInstance
{
  static __weak LSApplication* weakSingleInstance = nil;
  if (weakSingleInstance == nil)
  {
    LSApplication* singleInstance = [[LSApplication alloc] init];
    weakSingleInstance = singleInstance;
    return singleInstance;
  }
  return weakSingleInstance;
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  return self;
}

@end
