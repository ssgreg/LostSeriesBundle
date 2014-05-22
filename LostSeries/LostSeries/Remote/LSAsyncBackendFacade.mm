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
      NSMutableArray* episodes = [NSMutableArray array];
      // episodes
      int episodesSize = show.episodes_size();
      for (int j = 0; j < episodesSize; ++j)
      {
        LS::SeriesResponse_Episode episode = show.episodes(j);
        LSEpisodeInfo* episodeInfo = [[LSEpisodeInfo alloc] init];
        episodeInfo.name = [NSString stringWithUTF8String:episode.name().c_str()];
        episodeInfo.originalName = [NSString stringWithUTF8String:episode.originalname().c_str()];
        episodeInfo.number = episode.number();
        episodeInfo.dateTranslate = [self serverStringToDate:episode.datetranslate()];
        [episodes addObject:episodeInfo];
      }
      showInfo.episodes = episodes;
      //
      NSDate* dateEarliest = [NSDate date];
      for (LSEpisodeInfo* episode in episodes)
      {
        if ([dateEarliest compare:episode.dateTranslate] == NSOrderedDescending)
        {
          dateEarliest = episode.dateTranslate;
        }
      }
      NSCalendar* calendar = [NSCalendar currentCalendar];
      NSDateComponents* components = [calendar components:NSYearCalendarUnit fromDate:dateEarliest];
      showInfo.year = components.year;
      //
      [shows addObject:showInfo];
    }
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(shows);
    });
  }];
}

- (void) getArtworkByShowInfo:(LSShowInfo*)showInfo thumbnail:(BOOL)thumbnail replyHandler:(void (^)(NSData*))handler
{
  LS::ArtworkRequest artworkRequest;
  artworkRequest.set_idshow([showInfo.showID cStringUsingEncoding:NSASCIIStringEncoding]);
  artworkRequest.set_seasonnumber((int)showInfo.seasonNumber);
  artworkRequest.set_thumbnail(thumbnail);
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

- (void) subscribeByCDID:(LSCDID*)cdid subscriptionInfo:(NSArray*)subscriptions flagUnsubscribe:(BOOL)flagUnsibscribe replyHandler:(void (^)(BOOL result))handler;
{
  LS::SetSubscriptionRequest subscriptionRequest;
  subscriptionRequest.set_idclient([cdid toString].UTF8String);
  subscriptionRequest.set_flagunsubscribe(flagUnsibscribe);
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

- (void) getSubscriptionInfoArrayByCDID:(LSCDID*)cdid replyHandler:(void (^)(NSArray*))handler
{
  LS::GetSubscriptionRequest subscriptionRequest;
  subscriptionRequest.set_idclient([cdid toString].UTF8String);
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_getsubscriptionrequest() = subscriptionRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->mutable_getsubscriptionresponse(), @"Bad response!");
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

- (void) getUnwatchedEpisodesInfoArrayByCDID:(LSCDID*)cdid replyHandler:(void (^)(NSArray*))handler
{
  LS::GetUnwatchedSeriesRequest unwatchedSeriesRequest;
  unwatchedSeriesRequest.set_idclient([cdid toString].UTF8String);
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_getunwatchedseriesrequest() = unwatchedSeriesRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->mutable_getunwatchedseriesresponse(), @"Bad response!");
    LS::GetUnwatchedSeriesResponse const& message = reply->getunwatchedseriesresponse();
    //
    NSMutableArray* episodes = [NSMutableArray array];
    int episodeCount = message.episodes_size();
    for (int i = 0; i < episodeCount; ++i)
    {
      LS::GetUnwatchedSeriesResponse::Episode record = message.episodes(i);
      LSEpisodeUnwatchedInfo* info = [[LSEpisodeUnwatchedInfo alloc] init];
      info.idShow = [NSString stringWithCString:record.idshow().c_str() encoding:NSASCIIStringEncoding];
      info.numberSeason = record.numberseason();
      info.numberEpisode = record.numberepisode();
      //
      [episodes addObject:info];
    }
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(episodes);
    });
  }];
}

- (void) setUnwatchedEpisodesByCDID:(LSCDID*)cdid episodesUnwatched:(NSArray*)episodesUnwatched flagRemove:(BOOL)flagRemove replyHandler:(void (^)(BOOL result))handler
{
  LS::SetUnwatchedSeriesRequest unwatchedSeriesRequest;
  unwatchedSeriesRequest.set_idclient([cdid toString].UTF8String);
  unwatchedSeriesRequest.set_flagremove(flagRemove);
  for (LSEpisodeUnwatchedInfo* episode in episodesUnwatched)
  {
    LS::SetUnwatchedSeriesRequest::Episode* record = unwatchedSeriesRequest.add_episodes();
    record->set_idshow([episode.idShow cStringUsingEncoding:NSASCIIStringEncoding]);
    record->set_numberseason((int)episode.numberSeason);
    record->set_numberepisode((int)episode.numberEpisode);
  }
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_setunwatchedseriesrequest() = unwatchedSeriesRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->has_setunwatchedseriesresponse(), @"Bad response!");
    //
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(reply->setunwatchedseriesresponse().result());
    });
  }];
  
}

- (void) getSnapshotsRequest:(void (^)(LSSnapshotInfo*))handler
{
  LS::GetSnapshotsRequest snapshotRequest;
  //
  LSMessagePtr request(new LS::Message);
  *request->mutable_getsnapshotsrequest() = snapshotRequest;
  //
  [theConnection sendRequest:request replyHandler: ^(LSMessagePtr reply, NSData* data)
  {
    NSAssert(reply->has_getsnapshotsresponse(), @"Bad response!");
    //
    LSSnapshotInfo* snapshotInfo = [[LSSnapshotInfo alloc] init];
    dispatch_async(dispatch_get_main_queue(),
    ^{
      handler(snapshotInfo);
    });
  }];
}


- (NSDate*) serverStringToDate:(std::string const&) str
{
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss Z"];
  [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"]];
  return [dateFormatter dateFromString: [NSString stringWithUTF8String:str.c_str()]];
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


//
// LSEpisodeUnwatchedInfo
//

@implementation LSEpisodeUnwatchedInfo
// properties
@synthesize idShow;
@synthesize numberSeason;
@synthesize numberEpisode;
@end


//
// LSSnapshotInfo
//

@implementation LSSnapshotInfo

@end
