//
//  LSLocalCache.m
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSLocalCache.h"
// Protobuf
#include <Protobuf.Generated/LostSeriesProtocol.h>


//
// LSLocalCache
//

@interface LSLocalCache ()

- (NSString*) fileForRequest:(ZmqMessagePtr)request;
- (NSString*) fileNameFromSeriesRequest:(LS::SeriesRequest const&)request;
- (NSString*) fileNameFromArtworkRequest:(LS::ArtworkRequest const&)request;

@end

@implementation LSLocalCache

+ (LSLocalCache*) localCache
{
  return [[LSLocalCache alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  return self;
}

- (std::deque<ZmqMessagePtr>) cachedReplyForRequest:(ZmqMessagePtr)request
{
  std::deque<ZmqMessagePtr> result;
  //
  NSString* fileNameWithReplyBody = [self fileForRequest:request];
  if (!fileNameWithReplyBody)
  {
    return result;
  }
  NSString* fileNameWithReplyData = [fileNameWithReplyBody stringByAppendingString:@"-data"];
  //
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:fileNameWithReplyBody])
  {
    NSData* body = [NSData dataWithContentsOfFile:fileNameWithReplyBody];
    if (body && [body length] != 0)
    {
      ZmqMessagePtr bodyMessage(new zmq::message_t([body length]));
      memcpy(bodyMessage->data(), [body bytes], bodyMessage->size());
      result.push_back(bodyMessage);
    }
    if (!result.empty())
    {
      NSData* data = [NSData dataWithContentsOfFile:fileNameWithReplyData];
      if (data && [data length] != 0)
      {
        ZmqMessagePtr dataMessage(new zmq::message_t([data length]));
        memcpy(dataMessage->data(), [data bytes], dataMessage->size());
        result.push_back(dataMessage);
      }
    }
  }
  return result;
}

- (void) cacheReplyBody:(ZmqMessagePtr)replyBody andData:(ZmqMessagePtr)replyData forRequest:(ZmqMessagePtr)request
{
  NSString* fileNameWithReplyBody = [self fileForRequest:request];
  if (!fileNameWithReplyBody)
  {
    return;
  }
  NSString* fileNameWithReplyData = [fileNameWithReplyBody stringByAppendingString:@"-data"];
  //
  NSError* writeError = nil;
  NSData* body = [NSData dataWithBytes:replyBody->data() length:replyBody->size()];
  [body writeToFile:fileNameWithReplyBody options:NSDataWritingAtomic error:&writeError];
  if (!writeError && replyData)
  {
    NSData* data = [NSData dataWithBytes:replyData->data() length:replyData->size()];
    [data writeToFile:fileNameWithReplyData options:NSDataWritingAtomic error:&writeError];
    if (writeError)
    {
      [[NSFileManager defaultManager] removeItemAtPath:fileNameWithReplyData error:&writeError];
    }
  }
}

- (NSString*) fileForRequest:(ZmqMessagePtr)request
{
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* pathToDocuments = [paths objectAtIndex:0];
  NSString* fileName = nil;
  //
  LS::Message message;
  message.ParseFromArray(request->data(), (int)request->size());
  if (message.has_seriesrequest())
  {
    fileName = [self fileNameFromSeriesRequest:message.seriesrequest()];
  }
  else if (message.has_artworkrequest())
  {
    fileName = [self fileNameFromArtworkRequest:message.artworkrequest()];
  }
  else if (message.has_getsubscriptionrequest())
  {
    fileName = [self fileNameFromGetSubscriptionRequest:message.getsubscriptionrequest()];
  }
  else if (message.has_getunwatchedseriesrequest())
  {
    fileName = [self fileNameFromGetUnwatchedSeriesRequest:message.getunwatchedseriesrequest()];
  }
  else
  {
    return nil;
  }
  //
  return [pathToDocuments stringByAppendingFormat:@"/%@", fileName];
}

- (NSString*) fileNameFromSeriesRequest:(LS::SeriesRequest const&)request
{
  return [NSString stringWithFormat:@"seriesRequest"];
}

- (NSString*) fileNameFromArtworkRequest:(LS::ArtworkRequest const&)request
{
//  NSString* snapshot = [NSString stringWithCString:request.snapshot().c_str() encoding:NSASCIIStringEncoding];
  NSString* showID = [NSString stringWithCString:request.idshow().c_str() encoding:NSASCIIStringEncoding];
  return [NSString stringWithFormat:@"%@-%d-%d", showID, request.seasonnumber(), request.thumbnail()];
}

- (NSString*) fileNameFromGetSubscriptionRequest:(LS::GetSubscriptionRequest const&)request
{
  return [NSString stringWithFormat:@"getSubscriptionsRequest"];
}

- (NSString*) fileNameFromGetUnwatchedSeriesRequest:(LS::GetUnwatchedSeriesRequest const&)request
{
  return [NSString stringWithFormat:@"getUnwatchedSeriesRequest"];
}

@end
