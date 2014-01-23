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


@interface LSAsyncConnection : NSObject

#pragma mark - Factory Methods
+ (LSAsyncConnection*) asyncSocket;

#pragma mark - Init Methods
- (id) init;

#pragma mark - Interface

@end

@interface LSAsyncConnection ()
{
@private
  ZmqSocketPtr theFrontend;
}

@end

//
// LSConnection
//

@interface LSConnection ()
{
@private
  NSMutableDictionary* theHandlers;
  NSMutableDictionary* theRequests;
  int64_t theMessageID;
  //
  dispatch_queue_t thePollQueue;
  dispatch_queue_t theDataProtectionQueue;
  // priority sockets
  ZmqSocketPtr thePriorityBackend;
  ZmqSocketPtr thePriorityFrontend;
  ZmqSocketPtr thePriorityChannel;
}

- (void) startPollQueue;
- (LSChannel*) createChannel:(ZmqSocketPtr)socket;
- (void) send:(ZmqSocketPtr)socket request:(LS::Message)question complitionHandler:(id)handler;
- (void) dispatchMessageFrom:(ZmqSocketPtr)socket;
- (void) forwardMessageFrom:(ZmqSocketPtr)socketFrom to:(ZmqSocketPtr)socketTo;
- (NSString*) makeKey:(zmq::message_t const&)message;

- (ZmqMessagePtr) makeHeaderFrame:(NSInteger)messageID;
- (NSInteger) requestKeyFromHeaderFrame:(zmq::message_t&)headerFrame;

- (void) saveRequest:(zmq::message_t&)request forKey:(NSInteger)key;
- (ZmqMessagePtr) loadRequestForKey:(NSInteger)key;

@end

@implementation LSConnection

+ (LSConnection*) connection
{
  return [[LSConnection alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  static char const* backendAddres = "inproc://caching_server.frontend";
  static char const* frontendPriorityAddres = "inproc://server_routine.priority_request_puller";
  //
  theHandlers = [NSMutableDictionary dictionary];
  theRequests = [NSMutableDictionary dictionary];
  theMessageID = 0;
  thePollQueue = dispatch_queue_create("connection.poll.queue", NULL);
  theDataProtectionQueue = dispatch_queue_create("connection.data_protection.queue", NULL);
  //
  thePriorityBackend = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  thePriorityBackend->connect(backendAddres);
  thePriorityFrontend = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PULL));
  thePriorityFrontend->bind(frontendPriorityAddres);
  thePriorityChannel = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PUSH));
  thePriorityChannel->connect(frontendPriorityAddres);
  //
  [self startPollQueue];
  return self;
}

- (LSChannel*) createPriorityChannel
{
  return [self createChannel:thePriorityChannel];
}

- (void) startPollQueue
{
  dispatch_async(thePollQueue,
  ^{
    while (TRUE)
    {
      zmq_pollitem_t items [] =
      {
        { *thePriorityBackend, 0, ZMQ_POLLIN, 0 },
        { *thePriorityFrontend, 0, ZMQ_POLLIN, 0 },
      };
      if (zmq::poll(items, sizeof(items) / sizeof(zmq_pollitem_t)) <= 0)
      {
        continue;
      }
      if (items[0].revents & ZMQ_POLLIN)
      {
        dispatch_sync(theDataProtectionQueue,
        ^{
          [self dispatchMessageFrom:thePriorityBackend];
        });
      }
      else if (items[1].revents & ZMQ_POLLIN)
      {
        [self forwardMessageFrom:thePriorityFrontend to:thePriorityBackend];
      }
    }
  });
}

- (LSChannel*) createChannel:(ZmqSocketPtr)socket
{
  __weak typeof(self) weakSelf = self;
  void (^sendHandler)(LS::Message const&, id) = ^(LS::Message const& message, id handler)
  {
    __block LS::Message messageCopy = message;
    dispatch_async(theDataProtectionQueue,
    ^{
      [weakSelf send:socket request:messageCopy complitionHandler:handler];
    });
  };
  return [LSChannel serverChannelWithSendHandler: sendHandler];
}

- (void) send:(ZmqSocketPtr)socket request:(LS::Message)message complitionHandler:(id)handler
{
  NSLog(@"send begin = %@", [NSThread currentThread]);
  ++theMessageID;
  //
  ZmqMessagePtr requestBody = ZmqMessagePtr(new zmq::message_t(message.ByteSize()));
  message.SerializeToArray(requestBody->data(), (int)requestBody->size());
  //
  [self saveRequest:*requestBody forKey:theMessageID];
  //
  NSString* key = [self makeKey:*requestBody];
  if (NSMutableArray* handlers = [theHandlers objectForKey:key])
  {
    [handlers addObject:handler];
  }
  else
  {
    handlers = [NSMutableArray array];
    [handlers addObject:handler];
    [theHandlers setObject:handlers forKey:key];
    //
    std::deque<ZmqMessagePtr> multipartRequest;
    multipartRequest.push_back([self makeHeaderFrame:theMessageID]);
    multipartRequest.push_back(requestBody);
    ZmqSendMultipartMessage(socket, multipartRequest);
  }
  NSLog(@"send end = %@", [NSThread currentThread]);
}

- (void) dispatchMessageFrom:(ZmqSocketPtr)socket
{
  NSLog(@"dispatch = %@", [NSThread currentThread]);
  std::deque<ZmqMessagePtr> messages = ZmqRecieveMultipartMessage(socket);
  if (messages.front()->size() == 0)
  {
    messages.pop_front();
    ZmqMessagePtr requestBody;
    if (messages.size() == 2)
    {
      requestBody = [self loadRequestForKey:[self requestKeyFromHeaderFrame:*messages.front()]];
    }
    messages.pop_front();
    if (messages.size() == 1)
    {
      LS::Message answer;
      answer.ParseFromArray(messages.front()->data(), (int)messages.front()->size());
      //
      NSString* key = [self makeKey:*requestBody];
      NSArray* handlers = [theHandlers objectForKey:key];
      [theHandlers removeObjectForKey:key];
      NSLog(@"dispatch handlers = %@", [NSThread currentThread]);
      for (id handler in handlers)
      {
        ((void (^)(LS::Message const&))(handler))(answer);
      }
    }
  }
  NSLog(@"dispatch end = %@", [NSThread currentThread]);
}

- (void) forwardMessageFrom:(ZmqSocketPtr)socketFrom to:(ZmqSocketPtr)socketTo
{
  std::deque<ZmqMessagePtr> messages = ZmqRecieveMultipartMessage(socketFrom);
  NSAssert(messages.size() == 2, @"Something wrong with messages");
  messages.push_front(ZmqMessagePtr(new zmq::message_t()));
  ZmqSendMultipartMessage(socketTo, messages);
}

- (NSString*) makeKey:(zmq::message_t const&)message
{
  NSData* data = [NSData dataWithBytes:message.data() length:message.size()];
  return [data base64EncodedStringWithOptions:0];
}

- (ZmqMessagePtr) makeHeaderFrame:(NSInteger)messageID
{
  LS::Header header;
  header.set_messageid(messageID);
  //
  ZmqMessagePtr zmqHeader = ZmqMessagePtr(new zmq::message_t(header.ByteSize()));
  header.SerializeToArray(zmqHeader->data(), (int)zmqHeader->size());
  return zmqHeader;
}

- (NSInteger) requestKeyFromHeaderFrame:(zmq::message_t&)headerFrame
{
  LS::Header header;
  header.ParseFromArray(headerFrame.data(), (int)headerFrame.size());
  return header.messageid();
}

- (void) saveRequest:(zmq::message_t&)request forKey:(NSInteger)key
{
  NSData* data = [NSData dataWithBytes:request.data() length:request.size()];
  [theRequests setObject:data forKey:[NSNumber numberWithLongLong:key]];
}

- (ZmqMessagePtr) loadRequestForKey:(NSInteger)key
{
  ZmqMessagePtr request;
  if (NSData* data = [theRequests objectForKey:[NSNumber numberWithLongLong:key]])
  {
    request = ZmqMessagePtr(new zmq::message_t(data.length));
    memcpy(request->data(), [data bytes], request->size());
  }
  return request;
}

@end
