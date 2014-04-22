//
//  LSModelBase.m
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSModelBase.h"
#import "CachingServer/LSCachingServer.h"



//
// LSModelShowsLists
//

@implementation LSModelShowsLists
{
  NSArray* theShowsSource;
  JetArrayPartial* theShows;
  JetArrayPartial* theShowsFollowing;
  JetArrayPartial* theShowsSelected;
}

@synthesize shows = theShows;
@synthesize showsFollowing = theShowsFollowing;
@synthesize showsSelected = theShowsSelected;
@synthesize showsFiltered;
@synthesize showsFollowingFiltered;
@synthesize showsToChangeFollowing;

- (id) initWithShows:(NSArray*)shows
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theShowsSource = shows;
  theShows = [JetArrayPartial arrayPartialWithArraySource:theShowsSource];
  [theShows addAllObjects];
  //
  theShowsFollowing = [JetArrayPartial arrayPartialWithArraySource:theShowsSource];
  theShowsSelected = [JetArrayPartial arrayPartialWithArraySource:theShowsSource];
  showsFiltered = [JetArrayPartial arrayPartialWithArraySource:theShowsSource];
  showsFollowingFiltered = [JetArrayPartial arrayPartialWithArraySource:theShowsSource];
  showsToChangeFollowing = [JetArrayPartial arrayPartialWithArraySource:theShowsSource];
  //
  return self;
}

@end



//
// LSShowAlbumCellModel
//

@implementation LSShowAlbumCellModel
@end


//
// LSModelBase
//

@implementation LSModelBase
{
  LSCachingServer* theCachingServer;
  LSAsyncBackendFacade* theBackendFacade;
  dispatch_queue_t theQueueNotification;
  //
  NSArray* theShowsRaw;
  NSArray* theShowsFavoriteRaw;
  //
  BOOL theSelectionModeFlag;
  BOOL theFollowingModeFlag;
  LSModelShowsLists* theModelShowsLists;
  //
  LSShowAlbumCellModel* theShowForDetails;
  BOOL theFlagIsShowForDetailsFollowing;
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theCachingServer = [[LSCachingServer alloc] init];
  theBackendFacade = [LSAsyncBackendFacade backendFacade];
  theQueueNotification = dispatch_queue_create("modelbase.notification.queue", NULL);
  //
  theSelectionModeFlag = NO;
  return self;
}

- (void) modelDidChange
{
  dispatch_async(theQueueNotification,
  ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:LSModelBaseDidChange object:self];
  });
}

- (JetArrayPartial*) shows
{
  return theModelShowsLists.shows;
}

- (JetArrayPartial*) showsFiltered
{
  return theModelShowsLists.showsFiltered;
}

- (JetArrayPartial*) showsFollowing
{
  return theModelShowsLists.showsFollowing;
}

- (JetArrayPartial*) showsFollowingFiltered
{
  return theModelShowsLists.showsFollowingFiltered;
}

- (JetArrayPartial*) showsSelected
{
  return theModelShowsLists.showsSelected;
}

- (LSShowAlbumCellModel*) showForDetails
{
  return theShowForDetails;
}

- (void) setShowForDetails:(LSShowAlbumCellModel *)showForDetails
{
  theShowForDetails = showForDetails;
}

@synthesize modelShowsLists = theModelShowsLists;
@synthesize showsRaw = theShowsRaw;
@synthesize showsFavoriteRaw = theShowsFavoriteRaw;
@synthesize selectionModeActivated = theSelectionModeFlag;
@synthesize followingModeFollow = theFollowingModeFlag;
@synthesize backendFacade = theBackendFacade;

@end



//
// Notifications
//

NSString* LSModelBaseDidChange = @"LSModelBaseDidChange";
