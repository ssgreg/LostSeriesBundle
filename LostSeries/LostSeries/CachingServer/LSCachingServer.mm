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

@implementation LSCachingServer
{
  LSLocalCache* theLocalCache;
  dispatch_queue_t thePollQueue;
  //
  ZmqSocketPtr theFrontendSocket;
  ZmqSocketPtr theBackendSocket;
}

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
  //
  [self setupSockets];
  [self startPollQueue];
  //
  return self;
}

- (void) startPollQueue
{
  thePollQueue = dispatch_queue_create("caching_server.poll.queue", NULL);
  dispatch_async(thePollQueue,
  ^{
    std::map<int64_t, ZmqMessagePtr> idToRequestMap;
    while (YES)
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
          idToRequestMap[[self idMessage:multipartRequest]] = [self makeShortRequest:multipartRequest];
          ZmqSendMultipartMessage(theBackendSocket, multipartRequest);
        }
        else
        {
          ZmqSendMultipartMessage(theFrontendSocket, [self makeReplyFromRequest:multipartRequest andCachedReply:cachedReply]);
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
        //
        auto itRequest = idToRequestMap.find([self idMessage:multipartReply]);
        if (itRequest == idToRequestMap.end())
        {
          // TODO - warning!
          continue;
        }
        //
        [self cacheReply:multipartReply forRequest:itRequest->second];
        idToRequestMap.erase(itRequest);
        //
        ZmqSendMultipartMessage(theFrontendSocket, multipartReply);
      }
    }
  });
}

- (int64_t) idMessage:(std::deque<ZmqMessagePtr> const&)multipartMessage
{
  ZmqMessagePtr message = *(++multipartMessage.begin());
  LS::Header header;
  header.ParseFromArray(message->data(), (int)message->size());
  return header.messageid();
}

- (ZmqMessagePtr) makeShortRequest:(std::deque<ZmqMessagePtr> const&)requestMultipart
{
  std::deque<ZmqMessagePtr> requestMultipartShort;
  // skip router header, our header and zero frame
  auto it = requestMultipart.begin();
  ++it;
  ++it;
  ++it;
  for (; it != requestMultipart.end(); ++it)
  {
    requestMultipartShort.push_back(*it);
  }
  return ZmqCopyMultipartMessage(requestMultipartShort).front();
}

- (void) cacheReply:(std::deque<ZmqMessagePtr> const&)replyMultipart forRequest:(ZmqMessagePtr)request
{
  // skip router header, our header and zero frame
  auto it = replyMultipart.begin();
  ++it;
  ++it;
  ++it;
  ZmqMessagePtr replyBody = *it++;
  ZmqMessagePtr replyData = it == replyMultipart.end() ? ZmqMessagePtr() : *it;
  [theLocalCache cacheReplyBody:replyBody andData:replyData forRequest:request];
}

- (std::deque<ZmqMessagePtr>) makeReplyFromRequest:(std::deque<ZmqMessagePtr> const&)requestMultipart andCachedReply:(std::deque<ZmqMessagePtr> const&)replyCachedMultipart
{
  std::deque<ZmqMessagePtr> replyMultipart;
  // copy router header, our header and zero frame
  auto itRequest = requestMultipart.begin();
  replyMultipart.push_back(*itRequest++);
  replyMultipart.push_back(*itRequest++);
  replyMultipart.push_back(*itRequest++);
  // copy reply body
  replyMultipart.push_back(replyCachedMultipart.front());
  // copy reply data if exists
  if (replyCachedMultipart.size() > 1)
  {
    replyMultipart.push_back(replyCachedMultipart.back());
  }
  return replyMultipart;
}

- (void) setupSockets
{
  static char const* backendAddres = "tcp://server.lostseriesapp.com:8500"; // server.lostseriesapp.com
  static char const* frontendAddres = "inproc://caching_server.frontend";
  //
  theBackendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theBackendSocket->connect(backendAddres);
  theFrontendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_ROUTER));
  theFrontendSocket->bind(frontendAddres);
}

@end
