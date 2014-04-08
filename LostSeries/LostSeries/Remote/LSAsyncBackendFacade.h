//
//  LSProtocol.h
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>


// forwards
@class LSShowInfo;
@class LSSubscriptionInfo;


//
// LSAsyncBackendFacade
//

@interface LSAsyncBackendFacade : NSObject

#pragma mark - Factory Methods
+ (LSAsyncBackendFacade*) backendFacade;

#pragma mark - Init Methods
- (id) init;

#pragma mark - Interface
- (void) getShowInfoArray:(void (^)(NSArray*))handler;
- (void) getArtworkByShowInfo:(LSShowInfo*)showInfo thumbnail:(BOOL)thumbnail replyHandler:(void (^)(NSData*))handler;
- (void) subscribeByDeviceToken:(NSString*)deviceToken subscriptionInfo:(NSArray*)subscriptions replyHandler:(void (^)(BOOL result))handler;
- (void) getSubscriptionInfoArrayByDeviceToken:(NSString*)deviceToken replyHandler:(void (^)(NSArray*))handler;

@end


//
// LSEpisodeInfo
//

@interface LSEpisodeInfo : NSObject
@property NSString* name;
@property NSString* originalName;
@property NSInteger number;
@property NSDate* dateTranslate;
@end


//
// LSShowInfo
//

@interface LSShowInfo : NSObject
// properties
@property NSString* title;
@property NSString* originalTitle;
@property NSInteger seasonNumber;
@property NSInteger year;
@property NSString* showID;
@property NSString* snapshot;
@property NSArray* episodes;
@end


//
// LSSubscriptionInfo
//

@interface LSSubscriptionInfo : NSObject
// properties
@property NSString* showID;
@end
