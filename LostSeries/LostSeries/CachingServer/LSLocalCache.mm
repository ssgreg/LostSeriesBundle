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

- (NSInteger) messageIDFromRequest:(ZmqMessagePtr)request;
- (NSString*) fileNameFromRequest:(ZmqMessagePtr)request;
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

- (ZmqMessagePtr) cachedReplyForRequest:(ZmqMessagePtr)request
{
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* docs = [paths objectAtIndex:0];
  NSString* path = [docs stringByAppendingFormat:@"/%@", [self fileNameFromRequest:request]];
  
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:path])
  {
    NSData* replyData  = [NSData dataWithContentsOfFile:path];
    if (replyData && [replyData length] != 0)
    {
      LS::Message answer;
      answer.ParseFromArray([replyData bytes], (int)[replyData length]);
      answer.set_messageid([self messageIDFromRequest:request]);
      ZmqMessagePtr reply(new zmq::message_t(answer.ByteSize()));
      answer.SerializeToArray(reply->data(), (int)reply->size());
      return reply;
    }
  }
  return ZmqMessagePtr();
}

- (void) cacheReply:(ZmqMessagePtr)reply forRequest:(ZmqMessagePtr)request
{
  NSLog(@"request=%ld, reply=%ld", request->size(), reply->size());
  
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* docs = [paths objectAtIndex:0];
  NSString* path = [docs stringByAppendingFormat:@"/%@", [self fileNameFromRequest:request]];
  
  NSData* imageData = [NSData dataWithBytes:reply->data() length:reply->size()];
  NSError* writeError = nil;
  [imageData writeToFile:path options:NSDataWritingAtomic error:&writeError];

  if(writeError!=nil) {
    NSLog(@"%@: Error saving image: %@", [self class], [writeError localizedDescription]);
  }
}

- (NSString*) fileNameFromRequest:(ZmqMessagePtr)request
{
  LS::Message message;
  message.ParseFromArray(request->data(), (int)request->size());

  if (message.has_seriesrequest())
  {
    return [self fileNameFromSeriesRequest:message.seriesrequest()];
  }
  else if (message.has_artworkrequest())
  {
    return [self fileNameFromArtworkRequest:message.artworkrequest()];
  }

  return @"Unknown";
}

- (NSInteger) messageIDFromRequest:(ZmqMessagePtr)request
{
  LS::Message message;
  message.ParseFromArray(request->data(), (int)request->size());
  return message.messageid();
}

- (NSString*) fileNameFromSeriesRequest:(LS::SeriesRequest const&)request
{
  return [NSString stringWithFormat:@"seriesRequest"];
}

- (NSString*) fileNameFromArtworkRequest:(LS::ArtworkRequest const&)request
{
  NSData* plainData = [NSData dataWithBytes:request.originaltitle().data() length:request.originaltitle().size()];
  NSString* base64String = [plainData base64EncodedStringWithOptions:0];
  NSString* snapshotName = [NSString stringWithUTF8String: request.snapshot().c_str()];
  return [NSString stringWithFormat:@"%@-%@", snapshotName, base64String];
}

@end
