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
      showInfo.title = [NSString stringWithUTF8String: show.title().c_str()];
      showInfo.originalTitle = [NSString stringWithUTF8String: show.originaltitle().c_str()];
      showInfo.seasonNumber = show.seasonnumber();
      showInfo.snapshot = [NSString stringWithCString: show.snapshot().c_str() encoding:NSASCIIStringEncoding];
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
  artworkRequest.set_originaltitle(showInfo.originalTitle.UTF8String);
  artworkRequest.set_snapshot([showInfo.snapshot cStringUsingEncoding:NSASCIIStringEncoding]);
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

- (void) subscribeByDeviceToken:(NSString*)deviceToken subscriptionInfo:(NSArray*)subscriptions replyHandler:(void (^)())handler
{
  LS::SetSubscriptionRequest subscriptionRequest;
  subscriptionRequest.set_token(deviceToken.UTF8String);
  for (LSSubscriptionInfo* subscription in subscriptions)
  {
    LS::SubscriptionRecord* record = subscriptionRequest.add_subscriptions();
    record->set_originaltitle(subscription.originalTitle.UTF8String);
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
      handler();
    });
  }];
}

@end


//
// LSShowInfo
//

@implementation LSShowInfo
// properties
@synthesize title = theTitle;
@synthesize originalTitle = theOriginalTitle;
@synthesize seasonNumber = theSeasonNumber;
@synthesize snapshot = theSnapshot;
@end


//
// LSSubscriptionInfo
//

@implementation LSSubscriptionInfo
// properties
@synthesize originalTitle = theOriginalTitle;
@end
