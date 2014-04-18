//
//  LSWLinkActionChangeFollowing.m
//  LostSeries
//
//  Created by Grigory Zubankov on 18/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSWLinkActionChangeFollowing.h"
#import "Logic/LSApplication.h"


//
// LSWLinkActionChangeFollowing
//

@protocol LSDataActionChangeFollowing <LSDataBaseFacadeAsyncBackend, LSDataBaseShowsFollowing, LSDataBaseShowsSelected, LSDataBaseModeFollowing>
@end


@implementation LSWLinkActionChangeFollowing

SYNTHESIZE_WL_ACCESSORS(LSDataActionChangeFollowing, LSViewActionChangeFollowing);

- (void) input
{
  if (self.data.followingModeFollow)
  {
    [self.data.showsFollowing mergeObjectsFromArrayPartial:self.data.showsSelected];
  }
  else
  {
    [self.data.showsFollowing subtractObjectsFromArrayPartial:self.data.showsSelected];
  }
  //
  [self.view updateActionIndicatorChangeFollowing:YES];
  [self.data.backendFacade
   subscribeByCDID:[LSApplication singleInstance].cdid
   subscriptionInfo:self.makeSubscriptions
   flagUnsubscribe:!self.data.followingModeFollow
   replyHandler:^(BOOL result)
  {
    [self.view updateActionIndicatorChangeFollowing:NO];
    if (result)
    {
      [self output];
    }
  }];
  //
  [self forwardBlock];
}

- (NSArray*) makeSubscriptions
{
  NSMutableArray* subscriptions = [NSMutableArray array];
  for (LSShowAlbumCellModel* model in self.data.showsSelected)
  {
    LSSubscriptionInfo* subscription = [[LSSubscriptionInfo alloc] init];
    subscription.showID = model.showInfo.showID;
    //
    [subscriptions addObject:subscription];
  }
  return subscriptions;
}

@end
