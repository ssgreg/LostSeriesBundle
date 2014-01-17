//
//  LSProtocol.m
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSProtocol.h"


//
// LSProtocol
//

@interface LSProtocol ()
{
@private
  LSChannel* theChannel;
}

// send
- (void) send:(LS::Message const&)request completionHandler:(id)handler;

// dispatch
- (void) dispatchReply:(LS::Message const&)reply completionHandler:(id)handler;
- (void) handleSeriesReply:(LS::SeriesResponse const&)reply completionHandler:(void (^)(NSArray*))handler;
- (void) handleArtworkReply:(LS::ArtworkResponse const&)reply completionHandler:(void (^)(NSData*))handler;

@end

@implementation LSProtocol


+ (LSProtocol*) protocolWithChannel:(LSChannel*)channel;
{
  return [[LSProtocol alloc] initWithChannel:channel];
}

- (id) initWithChannel:(LSChannel*)channel
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theChannel = channel;
  return self;
}

- (void) send:(LS::Message const&)request completionHandler:(id)handler
{
  __weak typeof(self) weakSelf = self;
  void (^dispatchHandler)(LS::Message const&) = ^(LS::Message const& reply)
  {
    [weakSelf dispatchReply:reply completionHandler:handler];
  };
  [theChannel send:request completionHandler:dispatchHandler];
}

- (void) getShowInfoArray:(void (^)(NSArray*))handler
{
  LS::SeriesRequest seriesRequest;
  //
  LS::Message request;
  *request.mutable_seriesrequest() = seriesRequest;
  //
  [self send:request completionHandler:handler];
}

- (void) getArtwork:(LSShowInfo*)showInfo completionHandler:(void (^)(NSData*))handler
{
  LS::ArtworkRequest artworkRequest;
  artworkRequest.set_originaltitle([showInfo.originalTitle UTF8String]);
  artworkRequest.set_snapshot([showInfo.snapshot cStringUsingEncoding:NSASCIIStringEncoding]);
  //
  LS::Message request;
  *request.mutable_artworkrequest() = artworkRequest;
  //
  [self send:request completionHandler:handler];
}

- (void) dispatchReply:(LS::Message const&)reply completionHandler:(id)handler
{
  if (reply.has_seriesresponse())
  {
    [self handleSeriesReply:reply.seriesresponse() completionHandler:handler];
  }
  else if (reply.has_artworkresponse())
  {
    [self handleArtworkReply:reply.artworkresponse() completionHandler:handler];
  }
}

- (void) handleSeriesReply:(LS::SeriesResponse const&)reply completionHandler:(void (^)(NSArray*))handler
{
  NSMutableArray* shows = [NSMutableArray array];
  int showsSize = reply.shows_size();
  for (int i = 0; i < showsSize; ++i)
  {
    LS::SeriesResponse_TVShow show = reply.shows(i);
    LSShowInfo* showInfo = [LSShowInfo showInfo];
    showInfo.title = [NSString stringWithUTF8String: show.title().c_str()];
    showInfo.originalTitle = [NSString stringWithUTF8String: show.originaltitle().c_str()];
    showInfo.seasonNumber = show.seasonnumber();
    showInfo.snapshot = [NSString stringWithCString: show.snapshot().c_str() encoding:NSASCIIStringEncoding];
    //
    [shows addObject:showInfo];
  }
  handler(shows);
}

- (void) handleArtworkReply:(LS::ArtworkResponse const&)reply completionHandler:(void (^)(NSData*))handler
{
  std::string const& artwork = reply.artwork();
  if (!artwork.empty())
  {
    handler([NSData dataWithBytes:artwork.c_str() length:artwork.size()]);
  }
}

@end


//
// LSShowInfo
//

@implementation LSShowInfo

@synthesize title = theTitle;
@synthesize originalTitle = theOriginalTitle;
@synthesize seasonNumber = theSeasonNumber;
@synthesize snapshot = theSnapshot;

- (id) initWithTitle:(NSString*)title
       originalTitle:(NSString*)originalTitle
        seasonNumber:(NSInteger)seasonNumber
            snapshot:(NSString*)snapshot
{
  if (!(self = [super init]))
  {
    return nil;
  }
  [self setTitle:title];
  [self setOriginalTitle:originalTitle];
  [self setSeasonNumber:seasonNumber];
  [self setSnapshot:snapshot];
  return self;
}

+ (LSShowInfo*)showInfo
{
  return [[LSShowInfo alloc] init];
}

+ (LSShowInfo*)showInfoWithTitle:(NSString*)title
                   originalTitle:(NSString*)originalTitle
                    seasonNumber:(NSInteger)seasonNumber
                        snapshot:(NSString*)snapshot
{
  return [[LSShowInfo alloc] initWithTitle:title originalTitle:originalTitle seasonNumber:seasonNumber snapshot:snapshot];
}

@end
