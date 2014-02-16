//
//  LSApplication.h
//  LostSeries
//
//  Created by Grigory Zubankov on 10/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Cocoa
#import <Foundation/Foundation.h>
// LS
#import "LSModelBase.h"


//
// LSApplication
//

@interface LSApplication : NSObject

+ (LSApplication*) singleInstance;

// init
- (id) init;

@property NSString* deviceToken;
@property (readonly) LSModelBase* modelBase;

@end


//
// Notifications
//

extern NSString* LSApplicationDeviceTokenDidRecieveNotification; // device token has been recieved
