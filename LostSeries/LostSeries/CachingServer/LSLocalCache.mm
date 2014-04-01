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
//  NSString* fileNameWithReplyMessage = [self fileForRequest:request];
//  NSString* fileNameWithReplyData = [fileNameWithReplyMessage stringByAppendingString:@"-data"];
//  //
//  NSFileManager* fileManager = [NSFileManager defaultManager];
//  if ([fileManager fileExistsAtPath:fileNameWithReplyMessage])
//  {
//    NSData* replyMessageData = [NSData dataWithContentsOfFile:fileNameWithReplyMessage];
//    if (replyMessageData && [replyMessageData length] != 0)
//    {
//      ZmqMessagePtr replyMessage(new zmq::message_t([replyMessageData length]));
//      memcpy(replyMessage->data(), [replyMessageData bytes], replyMessage->size());
//      result.push_back(replyMessage);
//    }
//    if (!result.empty())
//    {
//      NSData* replyData = [NSData dataWithContentsOfFile:fileNameWithReplyData];
//      if (replyData && [replyData length] != 0)
//      {
//        ZmqMessagePtr replyBinary(new zmq::message_t([replyData length]));
//        memcpy(replyBinary->data(), [replyData bytes], replyBinary->size());
//        result.push_back(replyBinary);
//      }
//    }
//  }
  return result;
}

- (void) cacheReply:(std::deque<ZmqMessagePtr>)reply forRequest:(ZmqMessagePtr)request
{
  NSString* fileNameWithReplyMessage = [self fileForRequest:request];
  NSString* fileNameWithReplyData = [fileNameWithReplyMessage stringByAppendingString:@"-data"];
  // save reply message
  if (reply.empty())
  {
    return;
  }
  NSData* replyMessageData = [NSData dataWithBytes:reply.front()->data() length:reply.front()->size()];
  NSError* writeError = nil;
  [replyMessageData writeToFile:fileNameWithReplyMessage options:NSDataWritingAtomic error:&writeError];
  if (writeError)
  {
    return;
  }
  reply.pop_front();
  // save reply data
  if (reply.empty())
  {
    return;
  }
  NSData* replyData = [NSData dataWithBytes:reply.front()->data() length:reply.front()->size()];
  [replyData writeToFile:fileNameWithReplyData options:NSDataWritingAtomic error:&writeError];
  if (writeError)
  {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:fileNameWithReplyData error:&writeError];
    return;
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
  //
  return [pathToDocuments stringByAppendingFormat:@"/%@", fileName];
}

- (NSString*) fileNameFromSeriesRequest:(LS::SeriesRequest const&)request
{
  return [NSString stringWithFormat:@"seriesRequest"];
}

- (NSString*) fileNameFromArtworkRequest:(LS::ArtworkRequest const&)request
{
  NSString* snapshot = [NSString stringWithCString:request.snapshot().c_str() encoding:NSASCIIStringEncoding];
  NSString* showID = [NSString stringWithCString:request.idshow().c_str() encoding:NSASCIIStringEncoding];
  return [NSString stringWithFormat:@"%@-%@", snapshot, showID];
}

@end
