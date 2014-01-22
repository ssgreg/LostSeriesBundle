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
// LSConnection
//

@interface LSConnection ()
{
@private
  NSMutableDictionary* theHandlers;
  //
  dispatch_queue_t thePollQueue;
  int64_t theMessageID;
  // priority sockets
  ZmqSocketPtr thePriorityBackend;
  ZmqSocketPtr thePriorityFrontend;
  ZmqSocketPtr thePriorityChannel;
  // background sockets
  ZmqSocketPtr theBackgroundBackend;
  ZmqSocketPtr theBackgroundFrontend;
  ZmqSocketPtr theBackgroundChannel;
}

- (void) startPollQueue;
- (LSChannel*) createChannel:(ZmqSocketPtr)socket;
- (void) send:(ZmqSocketPtr)socket request:(LS::Message)question complitionHandler:(id)handler;
- (void) dispatchMessageFrom:(ZmqSocketPtr)socket;
- (void) forwardMessageFrom:(ZmqSocketPtr)socketFrom to:(ZmqSocketPtr)socketTo;

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
  static char const* frontendBackgroundAddres = "inproc://server_routine.background_request_puller";
  //
  theHandlers = [NSMutableDictionary dictionary];
  thePollQueue = dispatch_queue_create("server_dispatcher.proxy.queue", NULL);
  theMessageID = 0;
  //
  thePriorityBackend = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  thePriorityBackend->connect(backendAddres);
  thePriorityFrontend = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PULL));
  thePriorityFrontend->bind(frontendPriorityAddres);
  thePriorityChannel = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PUSH));
  thePriorityChannel->connect(frontendPriorityAddres);
  //
  theBackgroundBackend = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theBackgroundBackend->connect(backendAddres);
  theBackgroundFrontend = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PULL));
  theBackgroundFrontend->bind(frontendBackgroundAddres);
  theBackgroundChannel = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_PUSH));
  theBackgroundChannel->connect(frontendBackgroundAddres);
  //
  [self startPollQueue];
  return self;
}

- (LSChannel*) createPriorityChannel
{
  return [self createChannel:thePriorityChannel];
}

- (LSChannel*) createBackgroundChannel
{
  return [self createChannel:theBackgroundChannel];
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
        { *theBackgroundBackend, 0, ZMQ_POLLIN, 0 },
        { *theBackgroundFrontend, 0, ZMQ_POLLIN, 0 },
      };
      if (zmq::poll(items, sizeof(items) / sizeof(zmq_pollitem_t)) <= 0)
      {
        continue;
      }
      if (items[0].revents & ZMQ_POLLIN)
      {
        [self dispatchMessageFrom:thePriorityBackend];
      }
      else if (items[1].revents & ZMQ_POLLIN)
      {
        [self forwardMessageFrom:thePriorityFrontend to:thePriorityBackend];
      }
      if (items[2].revents & ZMQ_POLLIN)
      {
        [self dispatchMessageFrom:theBackgroundBackend];
      }
      else if (items[3].revents & ZMQ_POLLIN)
      {
        [self forwardMessageFrom:theBackgroundFrontend to:theBackgroundBackend];
      }
    }
  });
}

- (LSChannel*) createChannel:(ZmqSocketPtr)socket
{
  __weak typeof(self) weakSelf = self;
  void (^sendHandler)(LS::Message const&, id) = ^(LS::Message const& message, id handler)
  {
    [weakSelf send:socket request:message complitionHandler:handler];
  };
  return [LSChannel serverChannelWithSendHandler: sendHandler];
}

- (void) send:(ZmqSocketPtr)socket request:(LS::Message)message complitionHandler:(id)handler
{
  ++theMessageID;
  [theHandlers setObject:handler forKey: [NSNumber numberWithLongLong:theMessageID]];
  message.set_messageid(theMessageID);
  //
  zmq::message_t zmqRequest(message.ByteSize());
  message.SerializeToArray(zmqRequest.data(), (int)zmqRequest.size());
  //
  socket->send(zmqRequest, 0);
}

- (void) dispatchMessageFrom:(ZmqSocketPtr)socket
{
  std::deque<ZmqMessagePtr> messages = ZmqRecieveMultipartMessage(socket);
  if (messages.front()->size() == 0)
  {
    messages.pop_front();
    if (messages.size() == 1)
    {
      LS::Message answer;
      answer.ParseFromArray(messages.front()->data(), (int)messages.front()->size());
      //
      NSNumber* key = [NSNumber numberWithLongLong: answer.messageid()];
      id callback = [theHandlers objectForKey: key];
      [theHandlers removeObjectForKey:key];
      if (callback)
      {
        ((void (^)(LS::Message const&))(callback))(answer);
      }
    }
  }
}

- (void) forwardMessageFrom:(ZmqSocketPtr)socketFrom to:(ZmqSocketPtr)socketTo
{
  std::deque<ZmqMessagePtr> messages = ZmqRecieveMultipartMessage(socketFrom);
  if (messages.size() == 1)
  {
    socketTo->send(0, 0, ZMQ_SNDMORE);
    socketTo->send(*messages.front(), 0);
  }
}

@end
