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

@interface LSAsyncRequestReplyConnection ()
{
@private
  void (^theRecvHandler)(NSInteger, LSMessagePtr, NSData*);
  NSInteger theMessageID;
  dispatch_queue_t thePollQueue;
  ZmqSocketPtr theFrontend;
}

- (void) startPollQueue;
- (void) dispatchReply:(std::deque<ZmqMessagePtr>)multipartReply;
- (ZmqMessagePtr) makeRequestFrame:(LSMessagePtr)request;
- (ZmqMessagePtr) makeHeaderFrameWithMessageID:(NSInteger)messageID;
- (NSInteger) messageIDFromHeaderFrame:(ZmqMessagePtr)headerFrame;
- (LSMessagePtr) makeReplyWithReplyFrame:(ZmqMessagePtr)replyFrame;
- (NSData*) makeDataWithDataFrame:(ZmqMessagePtr)dataFrame;

@end

@implementation LSAsyncRequestReplyConnection

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
  thePollQueue = dispatch_queue_create("async_connection.poll.queue", NULL);
  //
  theFrontend = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theFrontend->connect([address UTF8String]);
  [self startPollQueue];
  //
  return self;
}

- (void) startPollQueue
{
  dispatch_async(thePollQueue,
  ^{
    while (TRUE)
    {
      zmq_pollitem_t items [] =
      {
        { *theFrontend, 0, ZMQ_POLLIN, 0 },
      };
      if (zmq::poll(items, sizeof(items) / sizeof(zmq_pollitem_t)) <= 0)
      {
        continue;
      }
      if (items[0].revents & ZMQ_POLLIN)
      {
        std::deque<ZmqMessagePtr> multipartReply = ZmqRecieveMultipartMessage(theFrontend);
        [self dispatchReply:multipartReply];
      }
    }
  });
}

- (void) dispatchReply:(std::deque<ZmqMessagePtr>)multipartReply
{
  // check for zero frame
  if (multipartReply.front()->size() != 0)
  {
    return;
  }
  multipartReply.pop_front();
  // check for header frame
  if (multipartReply.size() == 0)
  {
    return;
  }
  NSInteger replyID = [self messageIDFromHeaderFrame:multipartReply.front()];
  multipartReply.pop_front();
  // check for reply frame
  if (multipartReply.size() == 0)
  {
    return;
  }
  LSMessagePtr reply = [self makeReplyWithReplyFrame:multipartReply.front()];
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
  multipartRequest.push_back(ZmqZeroFrame());
  multipartRequest.push_back([self makeHeaderFrameWithMessageID:theMessageID]);
  multipartRequest.push_back([self makeRequestFrame:request]);
  ZmqSendMultipartMessage(theFrontend, multipartRequest);
  //
  return theMessageID++;
}

- (ZmqMessagePtr) makeRequestFrame:(LSMessagePtr)request
{
  ZmqMessagePtr requestBody = ZmqMessagePtr(new zmq::message_t(request->ByteSize()));
  request->SerializeToArray(requestBody->data(), (int)requestBody->size());
  return requestBody;
}

- (ZmqMessagePtr) makeHeaderFrameWithMessageID:(NSInteger)messageID
{
  LS::Header header;
  header.set_messageid(messageID);
  //
  ZmqMessagePtr zmqHeader = ZmqMessagePtr(new zmq::message_t(header.ByteSize()));
  header.SerializeToArray(zmqHeader->data(), (int)zmqHeader->size());
  return zmqHeader;
}

- (NSInteger) messageIDFromHeaderFrame:(ZmqMessagePtr)headerFrame
{
  LS::Header header;
  header.ParseFromArray(headerFrame->data(), (int)headerFrame->size());
  return header.messageid();
}

- (LSMessagePtr) makeReplyWithReplyFrame:(ZmqMessagePtr)replyFrame
{
  LSMessagePtr reply(new LS::Message);
  reply->ParseFromArray(replyFrame->data(), (int)replyFrame->size());
  return reply;
}

- (NSData*) makeDataWithDataFrame:(ZmqMessagePtr)dataFrame
{
  return [NSData dataWithBytes:dataFrame->data() length:dataFrame->size()];
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
