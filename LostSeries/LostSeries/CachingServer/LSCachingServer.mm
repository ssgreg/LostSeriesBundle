//
//  LSCachingServer.m
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSCachingServer.h"
#import "LSLocalCache.h"
// ZeroMQ
#include <ZeroMQ/ZeroMQ.h>


//
// LSCachingServer
//

@interface LSCachingServer ()
{
  LSLocalCache* theLocalCache;
  dispatch_queue_t thePollQueue;
  //
  ZmqContextPtr theContext;
  //
  ZmqSocketPtr theFrontendSocket;
  ZmqSocketPtr theBackendSocket;
}

- (void) startPollQueue;

@end

@implementation LSCachingServer

+ (LSCachingServer*) cachingServer
{
  return [[LSCachingServer alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  static char const* backendAddres = "tcp://localhost:8500";
  static char const* frontendAddres = "inproc://caching_server.frontend";
  //
  theLocalCache = [LSLocalCache localCache];
  thePollQueue = dispatch_queue_create("caching_server.poll.queue", NULL);
  //
  theContext = ZmqContextPtr(new zmq::context_t);
  //
  theBackendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theBackendSocket->connect(backendAddres);
  theFrontendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_REP));
  theFrontendSocket->bind(frontendAddres);
  //
  [self startPollQueue];
  //
  return self;
}

- (void) startPollQueue
{
  dispatch_async(thePollQueue,
  ^{
    ZmqMessagePtr lastRequest;
    while (TRUE)
    {
      zmq_pollitem_t items [] =
      {
        { *theFrontendSocket, 0, ZMQ_POLLIN, 0 },
        { *theBackendSocket, 0, ZMQ_POLLIN, 0 },
      };
      if (zmq::poll(items, sizeof(items) / sizeof(zmq_pollitem_t)) <= 0)
      {
        continue;
      }
      if (items[0].revents & ZMQ_POLLIN)
      {
        std::deque<ZmqMessagePtr> messages = ZmqRecieveMultipartMessage(theFrontendSocket);
        messages.push_front(ZmqMessagePtr(new zmq::message_t));
//        //
//        // copy last request for later usage
//        lastRequest = ZmqMessagePtr(new zmq::message_t);
//        lastRequest->copy(&*messages.back());
//        //
//        if (ZmqMessagePtr reply = [theLocalCache cachedReplyForRequest:lastRequest])
//        {
//          theFrontendSocket->send(*reply);
//        }
//        else
//        {
          ZmqSendMultipartMessage(theBackendSocket, messages);
//        }
      }
      else if (items[1].revents & ZMQ_POLLIN)
      {
        std::deque<ZmqMessagePtr> messages = ZmqRecieveMultipartMessage(theBackendSocket);
        messages.pop_front();
//        [theLocalCache cacheReply:messages.front() forRequest:lastRequest];
        ZmqSendMultipartMessage(theFrontendSocket, messages);
      }
    }
  });
}

@end
