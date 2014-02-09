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
- (void) getArtworkByShowInfo:(LSShowInfo*)showInfo replyHandler:(void (^)(NSData*))handler;
- (void) subscribeBySubscriptionInfo:(NSArray*)subscriptions replyHandler:(void (^)())handler;

@end


//
// LSShowInfo
//

@interface LSShowInfo : NSObject
// properties
@property NSString* title;
@property NSString* originalTitle;
@property NSInteger seasonNumber;
@property NSString* snapshot;
@end


//
// LSSubscriptionInfo
//

@interface LSSubscriptionInfo : NSObject
// properties
@property NSString* originalTitle;
@end
