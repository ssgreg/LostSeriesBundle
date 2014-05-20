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


namespace Cache
{
  
  //
  // RequestInfo
  //
  
  class RequestInfo
  {
  public:
    RequestInfo(ZmqMessagePtr requestBody, int64_t requestID);
    
  // interface
  public:
    ZmqMessagePtr RequestBody() const;
    int64_t RequestID() const;
    
  private:
    ZmqMessagePtr TheRequestBody;
    int64_t TheRequestID;
  };
  
  
  RequestInfo::RequestInfo(ZmqMessagePtr requestBody, int64_t requestID)
    : TheRequestBody(requestBody), TheRequestID(requestID)
  {}

  ZmqMessagePtr RequestInfo::RequestBody() const
  {
    return TheRequestBody;
  }
  
  int64_t RequestInfo::RequestID() const
  {
    return TheRequestID;
  }
  
  typedef std::list<RequestInfo> RequestInfoList;
  
  
  //
  // RequestInfoStorage
  //
  
  struct RequestInfoStorage
  {
    virtual void Put(RequestInfo const& requestInfo) = 0;
    virtual void Remove(int64_t requestID) = 0;
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
    virtual void Remove(int64_t requestID);
    
  // interface
  public:
    RequestInfoList Clear();
   
  private:
    NSString* FileNamePrefix() const;
    NSString* DirPath() const;
    NSString* FilePath(int64_t requestID) const;
  };

  
  RequestInfoLocalStorage::RequestInfoLocalStorage()
  {}
  
  void RequestInfoLocalStorage::Put(RequestInfo const& requestInfo)
  {
    NSData* data = [NSData dataWithBytes:requestInfo.RequestBody()->data() length:requestInfo.RequestBody()->size()];
    NSError* error = nil;
    [data writeToFile:FilePath(requestInfo.RequestID()) options:NSDataWritingAtomic error:&error];
  }

  void RequestInfoLocalStorage::Remove(int64_t requestID)
  {
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:FilePath(requestID) error:&error];
  }

  RequestInfoList RequestInfoLocalStorage::Clear()
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
      result.push_back(RequestInfo(requestBody, requestID));
      Remove(requestID);
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
  
  NSString* RequestInfoLocalStorage::FilePath(int64_t requestID) const
  {
    NSString* fileName = [NSString stringWithFormat:@"%@%lld", FileNamePrefix(), requestID];
    return [DirPath() stringByAppendingPathComponent:fileName];
  }
  
  typedef std::shared_ptr<RequestInfoLocalStorage> RequestInfoLocalStoragePtr;

  
  //
  // RequestQueue
  //
  
  class RequestQueue
  {
  public:
    RequestQueue(RequestInfoStoragePtr storage);
    
  // interface
  public:
    void Push(ZmqMultipartMessage const& request);
    ZmqMessagePtr TryToPop(ZmqMultipartMessage const& reply);
    
  private:
    RequestInfoStoragePtr TheStorage;
    RequestInfoList TheRequests;
  };

  
  RequestQueue::RequestQueue(RequestInfoStoragePtr storage)
    : TheStorage(storage)
  {}

  void RequestQueue::Push(ZmqMultipartMessage const& request)
  {
    TheRequests.push_back(RequestInfo(ZmqCopyFrame(request.back()), ZmqParseHeaderMessage(request.front())));
    TheStorage->Put(TheRequests.back());
  }
  
  ZmqMessagePtr RequestQueue::TryToPop(ZmqMultipartMessage const& reply)
  {
    RequestInfo requestTop = TheRequests.front();
    if (requestTop.RequestID() == ZmqParseHeaderMessage(reply.front()))
    {
      TheRequests.pop_front();
      TheStorage->Remove(requestTop.RequestID());
      return requestTop.RequestBody();
    }
    return ZmqMessagePtr();
  }
  
  typedef std::shared_ptr<RequestQueue> RequestQueuePtr;

  
  //
  // RequestManager
  //
  
  class RequestManager
  {
  public:
    RequestManager(RequestInfoStoragePtr storage);

  // interface
  public:
    ZmqMultipartMessage ReplyForRequest(ZmqMultipartMessage const& request);
    ZmqMultipartMessage ProcessRequest(ZmqMultipartMessage const& request);
    ZmqMultipartMessage ProcessReply(ZmqMultipartMessage const& reply);
  
  private:
    ZmqMultipartMessage MakeReply(ZmqMultipartMessage const& request, ZmqMultipartMessage const& replyCached);
    ZmqMultipartMessage WrapRequest(ZmqMultipartMessage request);
    ZmqMultipartMessage UnwrapReply(ZmqMultipartMessage const& replyWrapped);
    std::pair<ZmqMessagePtr, ZmqMessagePtr> GetBodyAndData(ZmqMultipartMessage const& reply);
    
  private:
    Cache::RequestQueuePtr TheRequestQueue;
    NSInteger TheMessageID;
    LSLocalCache* TheLocalCache;
  };

  RequestManager::RequestManager(RequestInfoStoragePtr storage)
    : TheRequestQueue(new Cache::RequestQueue(storage))
    , TheMessageID(0)
  {
    TheLocalCache = [LSLocalCache localCache];
  }
  
  ZmqMultipartMessage RequestManager::ReplyForRequest(ZmqMultipartMessage const& request)
  {
    ZmqMultipartMessage replyCached = [TheLocalCache cachedReplyForRequest:GetBodyAndData(request).first];
    return !replyCached.empty()
      ? MakeReply(request, replyCached)
      : ZmqMultipartMessage();
  }
  
  ZmqMultipartMessage RequestManager::ProcessRequest(ZmqMultipartMessage const& request)
  {
    ZmqMultipartMessage requestWrapped = WrapRequest(request);
    TheRequestQueue->Push(requestWrapped);
    return requestWrapped;
  }
  
  ZmqMultipartMessage RequestManager::ProcessReply(ZmqMultipartMessage const& replyWrapped)
  {
    ZmqMessagePtr requestBodyCached = TheRequestQueue->TryToPop(replyWrapped);
    if (!requestBodyCached)
    {
      // unexpected reply, drop it
      return ZmqMultipartMessage();
    }
    std::pair<ZmqMessagePtr, ZmqMessagePtr> bodyAndData = GetBodyAndData(replyWrapped);
    [TheLocalCache cacheReplyBody:bodyAndData.first andData:bodyAndData.second forRequest:requestBodyCached];
    //
    return UnwrapReply(replyWrapped);
  }
 
  ZmqMultipartMessage RequestManager::MakeReply(ZmqMultipartMessage const& request, ZmqMultipartMessage const& replyCached)
  {
    ZmqMultipartMessage reply;
    // use router header, our header and zero frame of request
    reply.insert(reply.end(), request.begin(), --request.end());
    // use reply body and data if exists
    reply.insert(reply.end(), replyCached.begin(), replyCached.end());
    return reply;
  }

  std::pair<ZmqMessagePtr, ZmqMessagePtr> RequestManager::GetBodyAndData(ZmqMultipartMessage const& reply)
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

  ZmqMultipartMessage RequestManager::WrapRequest(ZmqMultipartMessage request)
  {
    // add wrap id
    request.push_front(ZmqMakeHeaderMessage(++TheMessageID));
    return request;
  }

  ZmqMultipartMessage RequestManager::UnwrapReply(ZmqMultipartMessage const& replyWrapped)
  {
    // skip wrap id
    return std::deque<ZmqMessagePtr>(++replyWrapped.begin(), replyWrapped.end());
  }
  
  typedef std::shared_ptr<RequestManager> RequestManagerPtr;
  
}


//
// LSCachingServer
//

@implementation LSCachingServer
{
  Cache::RequestInfoLocalStoragePtr theRequestInfoStorage;
  Cache::RequestManagerPtr theRequestManager;
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
  theRequestInfoStorage.reset(new Cache::RequestInfoLocalStorage);
  theRequestManager.reset(new Cache::RequestManager(theRequestInfoStorage));
  //
  [self setupSockets];
  [self resendUnconfirmedRequests];
  [self startPollQueue];
  //
  return self;
}

- (void) startPollQueue
{
  dispatch_async(dispatch_queue_create("caching_server.poll.queue", NULL),
  ^{
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
        ZmqMultipartMessage request = ZmqRecieveMultipartMessage(theFrontendSocket);
        ZmqMultipartMessage reply = theRequestManager->ReplyForRequest(request);
        // use cached reply or ask server for it
        !reply.empty()
          ? ZmqSendMultipartMessage(theFrontendSocket, reply)
          : ZmqSendMultipartMessage(theBackendSocket, theRequestManager->ProcessRequest(request));
      }
      else if (items[1].revents & ZMQ_POLLIN)
      {
        ZmqMultipartMessage replyRaw = ZmqRecieveMultipartMessage(theBackendSocket);
        ZmqMultipartMessage reply = theRequestManager->ProcessReply(replyRaw);
        // drop reply that we dont wait
        if (reply.empty())
        {
          continue;
        }
        // drop reply w/o message id (usually resended requests)
        if (!reply.front()->size())
        {
          continue;
        }
        ZmqSendMultipartMessage(theFrontendSocket, reply);
      }
    }
  });
}

- (void) resendUnconfirmedRequests
{
  Cache::RequestInfoList requests = theRequestInfoStorage->Clear();
  for (Cache::RequestInfo const& requestInfo : requests)
  {
    ZmqMultipartMessage request;
    request.push_back(ZmqZeroFrame());
    request.push_back(requestInfo.RequestBody());
    //
    ZmqSendMultipartMessage(theBackendSocket, theRequestManager->ProcessRequest(request));
  }
}

- (void) setupSockets
{
  static char const* backendAddres = "tcp://localhost:8500"; // server.lostseriesapp.com
  static char const* frontendAddres = "inproc://caching_server.frontend";
  //
  theBackendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_DEALER));
  theBackendSocket->connect(backendAddres);
  theFrontendSocket = ZmqSocketPtr(new zmq::socket_t(ZmqGlobalContext(), ZMQ_ROUTER));
  theFrontendSocket->bind(frontendAddres);
}

@end
