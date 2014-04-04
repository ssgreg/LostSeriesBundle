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
#import "LSServiceArtworkGetter.h"
// LS.Logic
#import "Logic/LSRegistryControllers.h"


@class LSMessageBlackHole;


@interface LSMessageMBH : NSObject
- (id) initWithMessage:(NSString*) message delay:(double)delay;
@end


//
// LSMessageBlackHole
//

@interface LSMessageBlackHole : NSObject
- (void) queueNotification:(NSString*)message delay:(double)delay;
- (LSMessageMBH*) queueManagedNotification:(NSString*)message delay:(double)delay;
- (void) closeMessage:(LSMessageMBH*)message;
@end


//
// LSApplication
//

@interface LSApplication : NSObject <UIApplicationDelegate>

+ (LSApplication*) singleInstance;

// init
- (id) init;

@property NSString* deviceToken;
@property (readonly) LSModelBase* modelBase;
@property (readonly) LSServiceArtworkGetter* serviceArtworkGetter;
@property (readonly) LSMessageBlackHole* messageBlackHole;
@property (readonly) LSRegistryControllers* registryControllers;

@end


//
// Notifications
//

extern NSString* LSApplicationDeviceTokenDidRecieveNotification; // device token has been recieved
