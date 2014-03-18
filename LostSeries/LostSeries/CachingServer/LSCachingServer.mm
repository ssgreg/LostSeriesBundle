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
// Protobuf
#include <Protobuf.Generated/LostSeriesProtocol.h>
// ZeroMQ
#include <ZeroMQ/ZeroMQ.h>
// std
#include <map>


//
// LSCachingServer
//

@interface LSCachingServer ()
{
  LSLocalCache* theLocalCache;
  dispatch_queue_t thePollQueue;
  //
  ZmqSocketPtr theFrontendSocket;
  ZmqSocketPtr theBackendSocket;
}

- (void) startPollQueue;
- (int64_t) headerFrameID:(ZmqMessagePtr)headerFrame;
- (ZmqMessagePtr) copyRequest:(ZmqMessagePtr)request;

//- (ZmqMessagePtr) cachedReplyForRequest:(ZmqMessagePtr)request;
//- (void) cacheReply:(std::deque<ZmqMessagePtr>)reply forRequest:(ZmqMessagePtr)request;

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
  theLocalCache = [LSLocalCache localCache];
  thePollQueue = dispatch_queue_create("caching_server.poll.queue", NULL);
  //
  static char const* backendAddres = "tcp://localhost:8500"; // 188.226.138.15
  static char const* frontendAddres = "inproc://caching_server.frontend";
  theBackendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theBackendSocket->connect(backendAddres);
  theFrontendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_ROUTER));
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
    std::map<int64_t, ZmqMessagePtr> idToRequestMap;
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
        std::deque<ZmqMessagePtr> multipartRequest = ZmqRecieveMultipartMessage(theFrontendSocket);
        if (multipartRequest.size() != 4)
        {
          // TODO - warning!
          continue;
        }
        //
        std::deque<ZmqMessagePtr> cachedReply = [theLocalCache cachedReplyForRequest:multipartRequest.back()];
        if (cachedReply.empty())
        {
          idToRequestMap[[self headerFrameID:multipartRequest.front()]] = [self copyRequest:multipartRequest.back()];
          //
          ZmqSendMultipartMessage(theBackendSocket, multipartRequest);
        }
        else
        {
          // add request header to the cached reply
          cachedReply.push_front(multipartRequest.front());
          //
          ZmqSendMultipartMessage(theFrontendSocket, cachedReply);
        }
      }
      else if (items[1].revents & ZMQ_POLLIN)
      {
        std::deque<ZmqMessagePtr> multipartReply = ZmqRecieveMultipartMessage(theBackendSocket);
        if (multipartReply.size() < 4)
        {
          // TODO - warning!
          continue;
        }
//        ZmqMessagePtr header = multipartReply.front();
//        multipartReply.pop_front();
//        auto requestByID = idToRequestMap.find([self headerFrameID:header]);
//        if (requestByID == idToRequestMap.end())
//        {
//          // TODO - warning!
//          continue;
//        }
//        //
//        [theLocalCache cacheReply:multipartReply forRequest:requestByID->second];
//        idToRequestMap.erase(requestByID);
//        //
//        multipartReply.push_front(header);
            [NSThread sleepForTimeInterval:0.5];
        ZmqSendMultipartMessage(theFrontendSocket, multipartReply);
      }
    }
  });
}

- (int64_t) headerFrameID:(ZmqMessagePtr)headerFrame
{
  LS::Header header;
  header.ParseFromArray(headerFrame->data(), (int)headerFrame->size());
  return header.messageid();
}

- (ZmqMessagePtr) copyRequest:(ZmqMessagePtr)request
{
  ZmqMessagePtr result(new zmq::message_t);
  result->copy(&*request);
  return result;
}

@end
