//
//  LSLocalCache.h
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// ZeroMQ
#include <ZeroMQ/ZeroMQ.h>

//
// LSLocalCache
//

@interface LSLocalCache : NSObject

#pragma mark - Factory Methods
+ (LSLocalCache*) localCache;

#pragma mark - Init Methods
- (id) init;

#pragma mark - Interface
- (ZmqMessagePtr) cachedReplyForRequest:(ZmqMessagePtr)request;
- (void) cacheReply:(ZmqMessagePtr)reply forRequest:(ZmqMessagePtr)request;

@end
