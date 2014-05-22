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
  NSString* fileForReplyBody = nil;
  NSString* fileForReplyData = nil;
  if (![self filesFromRequestMessage:ZmqParseMessage(request) fileForReplyBody:&fileForReplyBody fileForReplyData:&fileForReplyData])
  {
    return result;
  }
  // try to load body
  if (ZmqMessagePtr body = [self readMessageFromFile:fileForReplyBody])
  {
    result.push_back(body);
    // try to load data
    if (ZmqMessagePtr data = [self readMessageFromFile:fileForReplyData])
    {
      result.push_back(data);
    }
  }
  return result;
}

- (void) cacheReplyBody:(ZmqMessagePtr)replyBody andData:(ZmqMessagePtr)replyData forRequest:(ZmqMessagePtr)request
{
  LSMessagePtr requestMessage = ZmqParseMessage(request);
  if (requestMessage->has_getsnapshotsrequest())
  {
    [self removeOutdatedFiles:replyBody];
  }
  else
  {
    [self writeReplyBody:replyBody andData:replyData forRequestMessage:requestMessage];
  }
}

- (void) removeOutdatedFiles:(ZmqMessagePtr)replyBody
{
  LS::GetSnapshotsResponse responseSnapshots = ZmqParseMessage(replyBody)->getsnapshotsresponse();
  // series
  LSMessagePtr responseSeries = [self cachedResponse:[self fileSeriesResponse]];
  if (responseSeries && responseSnapshots.snapshotseries() != responseSeries->seriesresponse().snapshot())
  {
    [self removeFromCache:[self fileSeriesResponse]];
  }
  // artworks
  int artworksCount = responseSnapshots.snapshotsartwork_size();
  for (int artworkIndex = 0; artworkIndex < artworksCount; ++artworkIndex)
  {
    LS::GetSnapshotsResponse_SnapshotArtwork snapshotArtwork = responseSnapshots.snapshotsartwork(artworkIndex);
    // thumbnail
    NSString* fileArtworkResponseThumbnail = [self fileArtworkRequest:snapshotArtwork.idshow() seasonNumber:snapshotArtwork.numberseason() thumbnail:YES];
    LSMessagePtr responseArtworkThumbnail = [self cachedResponse:fileArtworkResponseThumbnail];
    if (responseArtworkThumbnail && snapshotArtwork.snapshot() != responseArtworkThumbnail->artworkresponse().snapshot())
    {
      [self removeFromCache:fileArtworkResponseThumbnail];
    }
    // full-size
    NSString* fileArtworkResponse = [self fileArtworkRequest:snapshotArtwork.idshow() seasonNumber:snapshotArtwork.numberseason() thumbnail:NO];
    LSMessagePtr responseArtwork = [self cachedResponse:fileArtworkResponse];
    if (responseArtwork && snapshotArtwork.snapshot() != responseArtwork->artworkresponse().snapshot())
    {
      [self removeFromCache:fileArtworkResponse];
    }
  }
  // change requests
  [self removeFromCache:[self fileGetSubscriptionRequest]];
  [self removeFromCache:[self fileGetUnwatchedSeriesRequest]];
}

- (void) writeReplyBody:(ZmqMessagePtr)replyBody andData:(ZmqMessagePtr)replyData forRequestMessage:(LSMessagePtr)request
{
  NSString* fileForReplyBody = nil;
  NSString* fileForReplyData = nil;
  if (![self filesFromRequestMessage:request fileForReplyBody:&fileForReplyBody fileForReplyData:&fileForReplyData])
  {
    return;
  }
  //
  if ([self writeMessage:replyBody toFile:fileForReplyBody])
  {
    if (replyData && ![self writeMessage:replyData toFile:fileForReplyData])
    {
      [[NSFileManager defaultManager] removeItemAtPath:fileForReplyData error:nil];
    }
  }
}

- (BOOL) filesFromRequestMessage:(LSMessagePtr)message fileForReplyBody:(NSString**)fileForReplyBody fileForReplyData:(NSString**)fileForReplyData
{
  if (message->has_seriesrequest())
  {
    *fileForReplyBody = [self fileSeriesResponse];
  }
  else if (message->has_artworkrequest())
  {
    LS::ArtworkRequest artworkRequest = message->artworkrequest();
    *fileForReplyBody = [self fileArtworkRequest:artworkRequest.idshow() seasonNumber:artworkRequest.seasonnumber() thumbnail:artworkRequest.thumbnail()];
  }
  else if (message->has_getsubscriptionrequest())
  {
    *fileForReplyBody = [self fileGetSubscriptionRequest];
  }
  else if (message->has_getunwatchedseriesrequest())
  {
    *fileForReplyBody = [self fileGetUnwatchedSeriesRequest];
  }
  else
  {
    return NO;
  }
  *fileForReplyData = [*fileForReplyBody stringByAppendingString:@"-data"];
  return YES;
}

- (NSString*) fileSeriesResponse
{
  NSString* file = [NSString stringWithFormat:@"seriesRequest"];
  return [self.dirPath stringByAppendingPathComponent:file];
}

- (NSString*) fileArtworkRequest:(std::string const&)idShow seasonNumber:(int)seasonNumber thumbnail:(BOOL)thumbnail
{
  NSString* showID = [NSString stringWithCString:idShow.c_str() encoding:NSASCIIStringEncoding];
  NSString* file = [NSString stringWithFormat:@"%@-%d-%d", showID, seasonNumber, thumbnail];
  return [self.dirPath stringByAppendingPathComponent:file];
}

- (NSString*) fileGetSubscriptionRequest
{
  NSString* file = [NSString stringWithFormat:@"getSubscriptionsRequest"];
  return [self.dirPath stringByAppendingPathComponent:file];
}

- (NSString*) fileGetUnwatchedSeriesRequest
{
  NSString* file = [NSString stringWithFormat:@"getUnwatchedSeriesRequest"];
  return [self.dirPath stringByAppendingPathComponent:file];
}

- (NSString*) dirPath
{
  return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (BOOL) writeMessage:(ZmqMessagePtr)message toFile:(NSString*)file
{
  NSError* error = nil;
  [[self dataFromMessage:message] writeToFile:file options:NSDataWritingAtomic error:&error];
  return !error;
}

- (ZmqMessagePtr) readMessageFromFile:(NSString*)file
{
  NSData* data = [NSData dataWithContentsOfFile:file];
  return [self messageFromData:data];
}

- (NSData*) dataFromMessage:(ZmqMessagePtr)message
{
  return [NSData dataWithBytes:message->data() length:message->size()];
}

- (ZmqMessagePtr) messageFromData:(NSData*)data
{
  if (!data || !data.length)
  {
    return ZmqMessagePtr();
  }
  ZmqMessagePtr message(new zmq::message_t([data length]));
  memcpy(message->data(), [data bytes], message->size());
  return message;
}

- (void) removeFromCache:(NSString*)file
{
  [[NSFileManager defaultManager] removeItemAtPath:file error:nil];
}

- (LSMessagePtr) cachedResponse:(NSString*)file
{
  return ZmqParseMessage([self readMessageFromFile:file]);
}

@end
