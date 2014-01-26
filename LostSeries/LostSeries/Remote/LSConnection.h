//
//  LSConnection.h
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// Protobuf
#include <Protobuf.Generated/LostSeriesProtocol.h>


typedef std::shared_ptr<LS::Message> LSMessagePtr;


//
// LSAsyncRequestReplyConnection
//

@interface LSAsyncRequestReplyConnection : NSObject

#pragma mark - Factory Methods
+ (LSAsyncRequestReplyConnection*) connectionWithAddress:(NSString*)address RecvHandler:(void (^)(NSInteger, LSMessagePtr, NSData*))handler;

#pragma mark - Init Methods
- (id) initWithAddress:(NSString*)address RecvHandler:(void (^)(NSInteger, LSMessagePtr, NSData*))handler;

#pragma mark - Interface
// Not thread-safe
- (NSInteger) sendRequest:(LSMessagePtr)request;

@end


//
// LSAsyncRequestReplyHandlerBasedConnection
//

@interface LSAsyncRequestReplyHandlerBasedConnection : NSObject

#pragma mark - Factory Methods
+ (LSAsyncRequestReplyHandlerBasedConnection*) connectionWithAddress:(NSString*)address;

#pragma mark - Init Methods
- (id) initWithAddress:(NSString*)address;

#pragma mark - Interface
// Thread-safe
- (void) sendRequest:(LSMessagePtr)request replyHandler:(void (^)(LSMessagePtr, NSData*))handler;

@end
