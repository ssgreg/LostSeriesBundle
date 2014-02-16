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
  LSModelBase* theModelBase;
  NSString* theDeviceToken;
}
@end

@implementation LSApplication

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
  theModelBase = [[LSModelBase alloc] init];
  //
  return self;
}

- (NSString*) deviceToken
{
  return theDeviceToken;
}

- (void) setDeviceToken:(NSString *)deviceToken
{
  theDeviceToken = deviceToken;
  [[NSNotificationCenter defaultCenter] postNotificationName:LSApplicationDeviceTokenDidRecieveNotification object:self];
}

- (LSModelBase*) modelBase
{
  return theModelBase;
}

@end


NSString* LSApplicationDeviceTokenDidRecieveNotification = @"LSApplicationDeviceTokenDidRecieveNotification";
