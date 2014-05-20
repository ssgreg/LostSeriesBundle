//
//  LSConnection.m
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSConnection.h"
// ZeroMQ
#include <ZeroMQ/ZeroMQ.h>


//
// LSAsyncRequestReplyConnection
//

@implementation LSAsyncRequestReplyConnection
{
  void (^theRecvHandler)(NSInteger, LSMessagePtr, NSData*);
  NSInteger theMessageID;
  ZmqSocketPtr theServerSocket;
  ZmqSocketPtr theClientRecvSocket;
  ZmqSocketPtr theClientSendSocket;
}

+ (LSAsyncRequestReplyConnection*) connectionWithAddress:(NSString*)address replyHandler:(void (^)(NSInteger, LSMessagePtr, NSData*))handler
{
  return [[LSAsyncRequestReplyConnection alloc] initWithAddress:address replyHandler:handler];
}

- (id) initWithAddress:(NSString*)address replyHandler:(void (^)(NSInteger, LSMessagePtr, NSData*))handler
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theRecvHandler = handler;
  theMessageID = 0;
  //
  [self setupSockets:address];
  [self startPollQueue:address];
  //
  return self;
}

- (void) startPollQueue:(NSString*)address
{
  dispatch_async(dispatch_queue_create("async_connection.poll.queue", NULL),
  ^{
    while (TRUE)
    {
      zmq_pollitem_t items [] =
      {
        { *theServerSocket, 0, ZMQ_POLLIN, 0 },
        { *theClientRecvSocket, 0, ZMQ_POLLIN, 0 },
      };
      if (zmq::poll(items, sizeof(items) / sizeof(zmq_pollitem_t)) <= 0)
      {
        continue;
      }
      if (items[0].revents & ZMQ_POLLIN)
      {
        std::deque<ZmqMessagePtr> multipartReply = ZmqRecieveMultipartMessage(theServerSocket);
        [self dispatchReply:multipartReply];
      }
      if (items[1].revents & ZMQ_POLLIN)
      {
        std::deque<ZmqMessagePtr> multipartRequest = ZmqRecieveMultipartMessage(theClientRecvSocket);
        ZmqSendMultipartMessage(theServerSocket, multipartRequest);
      }
    }
  });
}

- (void) dispatchReply:(std::deque<ZmqMessagePtr>)multipartReply
{
  // check for header frame
  if (multipartReply.size() == 0)
  {
    return;
  }
  NSInteger replyID = ZmqParseHeaderMessage(multipartReply.front());
  multipartReply.pop_front();
  // check for zero frame
  if (multipartReply.front()->size() != 0)
  {
    return;
  }
  multipartReply.pop_front();
  // check for reply frame
  if (multipartReply.size() == 0)
  {
    return;
  }
  LSMessagePtr reply = ZmqParseMessage(multipartReply.front());
  multipartReply.pop_front();
  // check for optional data frame
  NSData* data = nil;
  if (multipartReply.size() > 0)
  {
    data = [self makeDataWithDataFrame:multipartReply.front()];
    multipartReply.pop_front();
  }
  // check for the end
  if (multipartReply.size() != 0)
  {
    return;
  }
  theRecvHandler(replyID, reply, data);
}

- (NSInteger) sendRequest:(LSMessagePtr)request
{
  std::deque<ZmqMessagePtr> multipartRequest;
  multipartRequest.push_back(ZmqMakeHeaderMessage(theMessageID));
  multipartRequest.push_back(ZmqZeroFrame());
  multipartRequest.push_back(ZmqMakeMessage(request));
  ZmqSendMultipartMessage(theClientSendSocket, multipartRequest);
  //
  return theMessageID++;
}

- (NSData*) makeDataWithDataFrame:(ZmqMessagePtr)dataFrame
{
  return [NSData dataWithBytes:dataFrame->data() length:dataFrame->size()];
}

- (void) setupSockets:(NSString*)address
{
  NSString* pushAddress = [NSString stringWithFormat:@"inproc://%@", [[NSUUID UUID] UUIDString]];
  //
  theServerSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theServerSocket->connect([address UTF8String]);
  theClientRecvSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PULL));
  theClientRecvSocket->bind([pushAddress UTF8String]);
  theClientSendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PUSH));
  theClientSendSocket->connect([pushAddress UTF8String]);
}

@end


//
// LSAsyncRequestReplyHandlerBasedConnection
//

@interface LSAsyncRequestReplyHandlerBasedConnection ()
{
@private
  LSAsyncRequestReplyConnection* theConnection;
  NSMutableDictionary* theHandlersDict;
  NSMutableDictionary* theRequestsDict;
  dispatch_queue_t theDataProtectionQueue;
}

- (void) dispatchReplyWithID:(NSInteger)replyID reply:(LSMessagePtr)reply data:(NSData*)data;

@end

@implementation LSAsyncRequestReplyHandlerBasedConnection

+ (LSAsyncRequestReplyHandlerBasedConnection*) connectionWithAddress:(NSString*)address
{
  return [[LSAsyncRequestReplyHandlerBasedConnection alloc] initWithAddress:address];
}

- (id) initWithAddress:(NSString*)address;
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  __weak typeof(self) weakSelf = self;
  theConnection = [LSAsyncRequestReplyConnection connectionWithAddress:address replyHandler:
    ^(NSInteger replyID, LSMessagePtr reply, NSData* data)
    {
      [weakSelf dispatchReplyWithID:replyID reply:reply data:data];
    }];
  theHandlersDict = [NSMutableDictionary dictionary];
  theRequestsDict = [NSMutableDictionary dictionary];
  theDataProtectionQueue = dispatch_queue_create("connection_helper.data_protection.queue", NULL);
  //
  return self;
}

- (void) sendRequest:(LSMessagePtr)request replyHandler:(void (^)(LSMessagePtr, NSData*))handler
{
  dispatch_async(theDataProtectionQueue,
  ^{
    NSMutableData* requestData = [NSMutableData dataWithLength:request->ByteSize()];
    request->SerializeToArray([requestData mutableBytes], (int)[requestData length]);
    NSString* encodedRequest = [requestData base64EncodedStringWithOptions:0];
    //
    if (NSMutableArray* handlers = [theHandlersDict objectForKey:encodedRequest])
    {
      [handlers addObject:handler];
    }
    else
    {
      NSInteger requestID = [theConnection sendRequest:request];
      //
      handlers = [NSMutableArray array];
      [handlers addObject:handler];
      [theHandlersDict setObject:handlers forKey:encodedRequest];
      [theRequestsDict setObject:encodedRequest forKey:[NSNumber numberWithLongLong:requestID]];
    }
  });
}

- (void) dispatchReplyWithID:(NSInteger)replyID reply:(LSMessagePtr)reply data:(NSData*)data
{
  dispatch_async(theDataProtectionQueue,
  ^{
    NSNumber* requestKey = [NSNumber numberWithLongLong:replyID];
    if (NSString* encodedRequest = [theRequestsDict objectForKey:requestKey])
    {
      NSArray* handlers = [theHandlersDict objectForKey:encodedRequest];
      [theHandlersDict removeObjectForKey:encodedRequest];
      [theRequestsDict removeObjectForKey:requestKey];
      for (id handler in handlers)
      {
        ((void (^)(LSMessagePtr, NSData*))(handler))(reply, data);
      }
    }
  });
}

@end
