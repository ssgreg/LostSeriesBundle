//
//  LSCachingServer.h
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>


//
// LSCachingServer
//

@interface LSCachingServer : NSObject

#pragma mark - Factory Methods
+ (LSCachingServer*) cachingServer;

#pragma mark - Init Methods
- (id) init;

@end
