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
  //
  NSArray* theShowsRaw;
  NSArray* theShowsFavoriteRaw;
  //
  BOOL theSelectionModeFlag;
  NSArray* theShows;
  NSDictionary* theFavoriteShows;
  NSDictionary* theSelectedShows;
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
  //
  theSelectionModeFlag = NO;
  return self;
}

@synthesize showsRaw = theShowsRaw;
@synthesize showsFavoriteRaw = theShowsFavoriteRaw;
@synthesize shows = theShows;
@synthesize favoriteShows = theFavoriteShows;
@synthesize selectedShows = theSelectedShows;
@synthesize selectionModeActivated = theSelectionModeFlag;
@synthesize backendFacade = theBackendFacade;

@end
