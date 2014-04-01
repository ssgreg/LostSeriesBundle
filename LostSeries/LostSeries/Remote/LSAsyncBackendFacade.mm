//
//  LSProtocol.m
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSAsyncBackendFacade.h"
#import "LSConnection.h"


//
// LSAsyncBackendFacade
//

@interface LSAsyncBackendFacade ()
{
@private
  LSAsyncRequestReplyHandlerBasedConnection* theConnection;
}

@end

@implementation LSAsyncBackendFacade


+ (LSAsyncBackendFacade*) backendFacade
{
  return [[LSAsyncBackendFacade alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  NSString* backendAddress = @"inproc://caching_server.frontend";
  theConnection = [LSAsyncRequestReplyHandlerBasedConnection connectionWithAddress:backendAddress];
  //
  return self;
}

- (void) getShowInfoArray:(void (^)(NSArray*))handler
{
  LS::SeriesRequest seriesRequest;
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_seriesrequest() = seriesRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->has_seriesresponse(), @"Bad response!");
    LS::SeriesResponse const& message = reply->seriesresponse();
    //
    NSMutableArray* shows = [NSMutableArray array];
    int showsSize = message.shows_size();
    for (int i = 0; i < showsSize; ++i)
    {
      LS::SeriesResponse_TVShow show = message.shows(i);
      LSShowInfo* showInfo = [[LSShowInfo alloc] init];
      showInfo.title = [NSString stringWithUTF8String:show.title().c_str()];
      showInfo.originalTitle = [NSString stringWithUTF8String:show.originaltitle().c_str()];
      showInfo.seasonNumber = show.seasonnumber();
      showInfo.showID = [NSString stringWithCString:show.id().c_str() encoding:NSASCIIStringEncoding];
      showInfo.snapshot = [NSString stringWithCString:show.snapshot().c_str() encoding:NSASCIIStringEncoding];
      NSMutableArray* episodes = [NSMutableArray array];
      int episodesSize = show.episodes_size();
      for (int j = 0; j < episodesSize; ++j)
      {
        LS::SeriesResponse_Episode episode = show.episodes(j);
        LSEpisodeInfo* episodeInfo = [[LSEpisodeInfo alloc] init];
        episodeInfo.name = [NSString stringWithUTF8String:episode.name().c_str()];
        episodeInfo.originalName = [NSString stringWithUTF8String:episode.originalname().c_str()];
        episodeInfo.number = episode.number();
        [episodes addObject:episodeInfo];
      }
      //
      [shows addObject:showInfo];
    }
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(shows);
    });
  }];
}

- (void) getArtworkByShowInfo:(LSShowInfo*)showInfo replyHandler:(void (^)(NSData*))handler
{
  LS::ArtworkRequest artworkRequest;
  artworkRequest.set_idshow([showInfo.showID cStringUsingEncoding:NSASCIIStringEncoding]);
  artworkRequest.set_seasonnumber((int)showInfo.seasonNumber);
  artworkRequest.set_thumbnail(YES);
//  artworkRequest.set_snapshot([showInfo.snapshot cStringUsingEncoding:NSASCIIStringEncoding]);
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_artworkrequest() = artworkRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->has_artworkresponse(), @"Bad response!");
    //
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(data);
    });
  }];
}

- (void) subscribeByDeviceToken:(NSString*)deviceToken subscriptionInfo:(NSArray*)subscriptions replyHandler:(void (^)(BOOL result))handler
{
  LS::SetSubscriptionRequest subscriptionRequest;
  subscriptionRequest.set_token(deviceToken.UTF8String);
  for (LSSubscriptionInfo* subscription in subscriptions)
  {
    LS::SubscriptionRecord* record = subscriptionRequest.add_subscriptions();
    record->set_id([subscription.showID cStringUsingEncoding:NSASCIIStringEncoding]);
  }
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_setsubscriptionrequest() = subscriptionRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->has_setsubscriptionresponse(), @"Bad response!");
    //
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(reply->setsubscriptionresponse().result());
    });
  }];
}

- (void) getSubscriptionInfoArrayByDeviceToken:(NSString*)deviceToken replyHandler:(void (^)(NSArray*))handler
{
  LS::GetSubscriptionRequest subscriptionRequest;
  subscriptionRequest.set_token(deviceToken.UTF8String);
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_getsubscriptionrequest() = subscriptionRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->mutable_getsubscriptionrequest(), @"Bad response!");
    LS::GetSubscriptionResponse const& message = reply->getsubscriptionresponse();
    //
    NSMutableArray* subscriptions = [NSMutableArray array];
    int subscriptionCount = message.subscriptions_size();
    for (int i = 0; i < subscriptionCount; ++i)
    {
      LS::SubscriptionRecord record = message.subscriptions(i);
      LSSubscriptionInfo* subscriptionInfo = [[LSSubscriptionInfo alloc] init];
      subscriptionInfo.showID = [NSString stringWithCString:record.id().c_str() encoding:NSASCIIStringEncoding];
      //
      [subscriptions addObject:subscriptionInfo];
    }
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(subscriptions);
    });
  }];
}

@end


//
// LSEpisodeInfo
//

@implementation LSEpisodeInfo
@synthesize name;
@synthesize originalName;
@synthesize number;
@end


//
// LSShowInfo
//

@implementation LSShowInfo
// properties
@synthesize title = theTitle;
@synthesize originalTitle = theOriginalTitle;
@synthesize seasonNumber = theSeasonNumber;
@synthesize showID = theShowID;
@synthesize snapshot = theSnapshot;
@synthesize episodes = theEpisodes;
@end


//
// LSSubscriptionInfo
//

@implementation LSSubscriptionInfo
// properties
@synthesize showID = theShowID;
@end
