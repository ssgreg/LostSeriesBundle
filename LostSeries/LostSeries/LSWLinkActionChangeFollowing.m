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

@implementation LSWLinkActionChangeFollowing

SYNTHESIZE_WL_ACCESSORS(LSDataActionChangeFollowing, LSViewActionChangeFollowing);

- (void) input
{
  [self.view updateActionIndicatorChangeFollowing:YES];
  //
  [self changeModel];
  //
  [self.data.backendFacade
    subscribeByCDID:[LSApplication singleInstance].cdid
    subscriptionInfo:[self transformToSubscription:self.data.showsToChange]
    flagUnsubscribe:!self.data.flagUnfollow
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

- (NSArray*) transformToSubscription:(JetArrayPartial*)shows
{
  NSMutableArray* subscriptions = [NSMutableArray array];
  for (LSShowAlbumCellModel* show in shows)
  {
    LSSubscriptionInfo* subscription = [[LSSubscriptionInfo alloc] init];
    subscription.showID = show.showInfo.showID;
    //
    [subscriptions addObject:subscription];
  }
  return subscriptions;
}

- (void) changeModel
{
  if (self.data.flagUnfollow)
  {
    [self.data.showsFollowing mergeObjectsFromArrayPartial:self.data.showsToChange];
  }
  else
  {
    [self.data.showsFollowing subtractObjectsFromArrayPartial:self.data.showsToChange];
  }
  //
  [self.data modelDidChange];
}

@end
