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
#import "JetNetworkReachibility.h"
// Protobuf
#include <Protobuf.Generated/LostSeriesProtocol.h>
// ZeroMQ
#include <ZeroMQ/ZeroMQ.h>

#include <ifaddrs.h>
#include <arpa/inet.h>



namespace Cache
{
  
  //
  // ContinuousCounter
  //
  class ContinuousCounter
  {
  public:
    ContinuousCounter(NSString* name);
    
  // interface
  public:
    NSInteger Next();
    NSInteger Get();
    
  private:
    NSInteger TryToReadCounter() const;
    NSString* FilePath() const;
    
  public:
    NSString* TheName;
    NSInteger TheCachedID;
  };
  
  
  ContinuousCounter::ContinuousCounter(NSString* name)
    : TheName(name)
    , TheCachedID(TryToReadCounter())
  {
  }
  
  NSInteger ContinuousCounter::Next()
  {
    ++TheCachedID;
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithInteger:TheCachedID]];
    NSError* error = nil;
    [data writeToFile:FilePath() options:NSDataWritingAtomic error:&error];
    return TheCachedID;
  }
  
  NSInteger ContinuousCounter::Get()
  {
    return TheCachedID;
  }
  
  NSInteger ContinuousCounter::TryToReadCounter() const
  {
    NSData* data = [NSData dataWithContentsOfFile:FilePath()];
    return data
      ? [[NSKeyedUnarchiver unarchiveObjectWithData:data] integerValue]
      : NSInteger();
  }

  NSString* ContinuousCounter::FilePath() const
  {
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [path stringByAppendingPathComponent:TheName];
  }

  typedef std::shared_ptr<ContinuousCounter> ContinuousCounterPtr;
  
  
  //
  // RequestInfo
  //
  
  class RequestInfo
  {
  public:
    RequestInfo(ZmqMultipartMessage request);
    
  // interface
  public:
    ZmqMultipartMessage Request() const;
    ZmqMessagePtr RequestBody() const;
    NSInteger RequestID() const;
    
  private:
    ZmqMultipartMessage TheRequest;
  };
  

  ZmqMultipartMessage RequestInfo::Request() const
  {
    return TheRequest;
  }

  RequestInfo::RequestInfo(ZmqMultipartMessage request)
    : TheRequest(ZmqCopyMultipartMessage(request))
  {}

  ZmqMessagePtr RequestInfo::RequestBody() const
  {
    return TheRequest.empty()
      ? ZmqMessagePtr()
      : TheRequest.back();
  }

  NSInteger RequestInfo::RequestID() const
  {
    return ZmqParseHeaderMessage(TheRequest.front());
  }
  
  typedef std::list<RequestInfo> RequestInfoList;
  
  
  //
  // RequestInfoStorage
  //
  
  struct RequestInfoStorage
  {
    virtual void Put(RequestInfo const& requestInfo) = 0;
    virtual void Remove(NSInteger requestID) = 0;
    virtual RequestInfoList GetAll() = 0;
  };
  
  typedef std::shared_ptr<RequestInfoStorage> RequestInfoStoragePtr;
  
  
  //
  // RequestInfoLocalStorage
  //
  
  class RequestInfoLocalStorage : public RequestInfoStorage
  {
  public:
    RequestInfoLocalStorage();
    
  // RequestInfoStorage interface
  public:
    virtual void Put(RequestInfo const& requestInfo);
    virtual void Remove(NSInteger requestID);
    virtual RequestInfoList GetAll();
   
  private:
    NSString* FileNamePrefix() const;
    NSString* DirPath() const;
    NSString* FilePath(NSInteger requestID) const;
  };

  
  RequestInfoLocalStorage::RequestInfoLocalStorage()
  {}
  
  void RequestInfoLocalStorage::Put(RequestInfo const& requestInfo)
  {
    NSData* data = [NSData dataWithBytes:requestInfo.RequestBody()->data() length:requestInfo.RequestBody()->size()];
    NSError* error = nil;
    [data writeToFile:FilePath(requestInfo.RequestID()) options:NSDataWritingAtomic error:&error];
  }

  void RequestInfoLocalStorage::Remove(NSInteger requestID)
  {
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:FilePath(requestID) error:&error];
  }

  RequestInfoList RequestInfoLocalStorage::GetAll()
  {
    NSPredicate* filter = [NSPredicate predicateWithFormat:@"self BEGINSWITH %@", FileNamePrefix()];
    NSArray* filesAll = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DirPath() error:nil];
    NSArray* filesRequests = [filesAll filteredArrayUsingPredicate:filter];
    //
    RequestInfoList result;
    for (NSString* fileRequest in filesRequests)
    {
      NSInteger requestID = 0;
      if (![[NSScanner scannerWithString:[fileRequest substringFromIndex:FileNamePrefix().length]] scanInteger:&requestID])
      {
        continue;
      }
      NSData* dataRequestBody = [NSData dataWithContentsOfFile:[DirPath() stringByAppendingPathComponent:fileRequest]];
      ZmqMessagePtr requestBody(new zmq::message_t([dataRequestBody length]));
      memcpy(requestBody->data(), [dataRequestBody bytes], requestBody->size());
      //
      ZmqMultipartMessage request;
      request.push_back(ZmqMakeHeaderMessage(requestID));
      request.push_back(ZmqZeroFrame());
      request.push_back(requestBody);
      //
      result.push_back(RequestInfo(request));
    }
    return result;
  }
  
  NSString* RequestInfoLocalStorage::FileNamePrefix() const
  {
    return @"request-";
  }
  
  NSString* RequestInfoLocalStorage::DirPath() const
  {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  }
  
  NSString* RequestInfoLocalStorage::FilePath(NSInteger requestID) const
  {
    NSString* fileName = [NSString stringWithFormat:@"%@%ld", FileNamePrefix(), requestID];
    return [DirPath() stringByAppendingPathComponent:fileName];
  }
  
  typedef std::shared_ptr<RequestInfoLocalStorage> RequestInfoLocalStoragePtr;

  
  //
  // RequestQueue
  //
  
  class RequestQueue
  {
  public:
    RequestQueue();
    
  // interface
  public:
    RequestInfo Push(ZmqMultipartMessage const& request);
    RequestInfo TryToPop(ZmqMultipartMessage const& reply);
    RequestInfoList GetAll() const;
    
  private:
    RequestInfoList TheRequests;
  };

  
  RequestQueue::RequestQueue()
  {}

  RequestInfo RequestQueue::Push(ZmqMultipartMessage const& request)
  {
    RequestInfo requestInfo = RequestInfo(request);
    TheRequests.push_back(requestInfo);
    return requestInfo;
  }
  
  RequestInfo RequestQueue::TryToPop(ZmqMultipartMessage const& reply)
  {
    RequestInfo requestTop = TheRequests.front();
    if (requestTop.RequestID() == ZmqParseHeaderMessage(reply.front()))
    {
      TheRequests.pop_front();
      return requestTop;
    }
    return RequestInfo(ZmqMultipartMessage());
  }

  RequestInfoList RequestQueue::GetAll() const
  {
    return TheRequests;
  }
  
  typedef std::shared_ptr<RequestQueue> RequestQueuePtr;
  
}


//
// LSCachingServer
//

@implementation LSCachingServer
{
  Cache::ContinuousCounterPtr theMessageCounter;
  Cache::RequestInfoStoragePtr theRequestInfoStorage;
  Cache::RequestQueuePtr theRequestQueue;
  LSLocalCache* theLocalCache;
  //
  ZmqSocketPtr theFrontendSocket;
  ZmqSocketPtr theBackendSocket;
  //
  ZmqSocketPtr theFrontendSocket1;
  ZmqSocketPtr theBackendSocket1;
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
  [self setupSockets];
  [self startPollQueue];
  //
  [[NSNotificationCenter defaultCenter]
    addObserverForName:JetNetworkReachibilityDidChange
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification* notification)
  {
    theBackendSocket1->send("Test", 4);
  }];

  return self;
}

- (BOOL) string:(char const*)str hasPrefix:(char const*)prefix
{
  while (*str && *prefix)
  {
    if (*str++ != *prefix++)
    {
      return false;
    }
  }
  return true;
}


- (NSString *)getIPAddress
{
  char const* ipCellular = nil;
  char const* ipWiFi = nil;
  char const* ipLocal = "127.0.0.1";
  
  ifaddrs* interfaces = nil;
  if (getifaddrs(&interfaces) == 0)
  {
    ifaddrs* cursor = interfaces;
    while(cursor)
    {
      ipLocal = inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr);
      if(cursor->ifa_addr->sa_family == AF_INET)
      {
        if ([self string:cursor->ifa_name hasPrefix:"lo"])
        {
          ipLocal = inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr);
        }
        else if ([self string:cursor->ifa_name hasPrefix:"en"])
        {
          ipWiFi = inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr);
        }
        else if ([self string:cursor->ifa_name hasPrefix:"pdp_ip"])
        {
          ipCellular = inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr);
        }
      }
      cursor = cursor->ifa_next;
    }
  }
  freeifaddrs(interfaces);
  return [NSString stringWithUTF8String:ipWiFi ? ipWiFi : (ipCellular ? ipCellular : ipLocal)];
}

- (void) startPollQueue
{
  dispatch_async(dispatch_queue_create("caching_server.poll.queue", NULL),
  ^{
    theLocalCache = [LSLocalCache localCache];
    theMessageCounter.reset(new Cache::ContinuousCounter(@"caching_server.message.counter"));
    theRequestInfoStorage.reset(new Cache::RequestInfoLocalStorage);
    theRequestQueue.reset(new Cache::RequestQueue);
    [self resendUnconfirmedRequestsFromLastSession];
    //
    while (YES)
    {
      zmq_pollitem_t items [] =
      {
        { *theFrontendSocket, 0, ZMQ_POLLIN, 0 },
        { *theBackendSocket, 0, ZMQ_POLLIN, 0 },
        { *theFrontendSocket1, 0, ZMQ_POLLIN, 0 },
      };
      if (zmq::poll(items, sizeof(items) / sizeof(zmq_pollitem_t)) <= 0)
      {
        continue;
      }
      if (items[0].revents & ZMQ_POLLIN)
      {
        ZmqMultipartMessage request = ZmqRecieveMultipartMessage(theFrontendSocket);
        ZmqMultipartMessage reply = [self replyForRequest:request];
        // use cached reply or ask server for it
        !reply.empty()
          ? ZmqSendMultipartMessage(theFrontendSocket, reply)
          : ZmqSendMultipartMessage(theBackendSocket, [self processRequest:request]);
      }
      else if (items[1].revents & ZMQ_POLLIN)
      {
        ZmqMultipartMessage replyRaw = ZmqRecieveMultipartMessage(theBackendSocket);
        ZmqMultipartMessage reply = [self processReply:replyRaw];
        // drop reply that we dont wait
        if (reply.empty())
        {
          continue;
        }
        // drop reply w/o client id (usually resended requests)
        if (!reply.front()->size())
        {
          continue;
        }
        ZmqSendMultipartMessage(theFrontendSocket, reply);
      }
      else if (items[2].revents & ZMQ_POLLIN)
      {
        ZmqMultipartMessage request = ZmqRecieveMultipartMessage(theFrontendSocket1);
        static char const* backendAddres = "tcp://188.226.138.15:8500"; // server.lostseriesapp.com
        //
        theBackendSocket->disconnect(backendAddres);
        theBackendSocket->connect(backendAddres);
        [self resendUnconfirmedRequestsFromQueue];
      }
    }
  });
}

- (void) resendUnconfirmedRequestsFromLastSession
{
  Cache::RequestInfoList requests = theRequestInfoStorage->GetAll();
  for (Cache::RequestInfo const& requestInfo : requests)
  {
    ZmqMultipartMessage request = [self unwrapReply:requestInfo.Request()];
    // resend request
    ZmqMultipartMessage requestWrapped = [self processRequest:request];
    ZmqSendMultipartMessage(theBackendSocket, requestWrapped);
    // safe place to remove unconfirmed request
    theRequestInfoStorage->Remove(requestInfo.RequestID());
  }
}

- (void) resendUnconfirmedRequestsFromQueue
{
  // get all in-memory requests
  Cache::RequestInfoList requests = theRequestQueue->GetAll();
  // recreate queue (no need to wait for old requests)
  theRequestQueue.reset(new Cache::RequestQueue);
  for (Cache::RequestInfo const& requestInfo : requests)
  {
    ZmqMultipartMessage request = [self unwrapReply:requestInfo.Request()];
    // resend request
    ZmqMultipartMessage requestWrapped = [self processRequest:request];
    ZmqSendMultipartMessage(theBackendSocket, requestWrapped);
    // safe place to remove unconfirmed request
    theRequestInfoStorage->Remove(requestInfo.RequestID());
  }
}

- (ZmqMultipartMessage) processRequest:(ZmqMultipartMessage const&)request
{
  // add out message id
  ZmqMultipartMessage requestWrapped = [self wrapRequest:request];
  // store request in memory and in file
  Cache::RequestInfo requestInfo = theRequestQueue->Push(requestWrapped);
  theRequestInfoStorage->Put(requestInfo);
  //
  return requestWrapped;
}

- (ZmqMultipartMessage) processReply:(ZmqMultipartMessage const&)replyWrapped
{
  Cache::RequestInfo requestInfo = theRequestQueue->TryToPop(replyWrapped);
  if (!requestInfo.RequestBody())
  {
    // unexpected reply, drop it
    return ZmqMultipartMessage();
  }
  std::pair<ZmqMessagePtr, ZmqMessagePtr> bodyAndData = [self getBodyAndData:replyWrapped];
  [theLocalCache cacheReplyBody:bodyAndData.first andData:bodyAndData.second forRequest:requestInfo.RequestBody()];
  // safe place to remove unconfirmed request
  theRequestInfoStorage->Remove(requestInfo.RequestID());
  //
  return [self unwrapReply:replyWrapped];
}

- (ZmqMultipartMessage) replyForRequest:(ZmqMultipartMessage const&)request
{
  ZmqMultipartMessage replyCached = [theLocalCache cachedReplyForRequest:[self getBodyAndData:request].first];
  return !replyCached.empty()
    ? [self makeReplyFromRequest:request cachedReply:replyCached]
    : ZmqMultipartMessage();
}

- (ZmqMultipartMessage) wrapRequest:(ZmqMultipartMessage)request
{
  request.push_front(ZmqMakeHeaderMessage(theMessageCounter->Next()));
  return request;
}

- (ZmqMultipartMessage) unwrapReply:(ZmqMultipartMessage const&)replyWrapped
{
  return std::deque<ZmqMessagePtr>(++replyWrapped.begin(), replyWrapped.end());
}

- (ZmqMultipartMessage) makeReplyFromRequest:(ZmqMultipartMessage const&)request cachedReply:(ZmqMultipartMessage const&)replyCached
{
  ZmqMultipartMessage reply;
  // use router header, our header and zero frame of request
  reply.insert(reply.end(), request.begin(), --request.end());
  // use reply body and data if exists
  reply.insert(reply.end(), replyCached.begin(), replyCached.end());
  return reply;
}

- (std::pair<ZmqMessagePtr, ZmqMessagePtr>) getBodyAndData:(ZmqMultipartMessage const&)reply
{
  std::pair<ZmqMessagePtr, ZmqMessagePtr> result;
  for (auto it = reply.begin(); it != reply.end(); ++it)
  {
    if (!(*it)->size())
    {
      if (++it != reply.end())
      {
        result.first = *it;
      }
      if (++it != reply.end())
      {
        result.second = *it;
      }
      break;
    }
  }
  return result;
}

- (void) setupSockets
{
  
  static char const* backendAddres = "tcp://188.226.138.15:8500"; // server.lostseriesapp.com
  static char const* frontendAddres = "inproc://caching_server.frontend";
  //
  theBackendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theBackendSocket->connect(backendAddres);
  theFrontendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_ROUTER));
  theFrontendSocket->bind(frontendAddres);

  static char const* configAddres = "inproc://caching_server.config";

  theBackendSocket1 = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theBackendSocket1->connect(configAddres);
  theFrontendSocket1 = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_ROUTER));
  theFrontendSocket1->bind(configAddres);
}

@end
