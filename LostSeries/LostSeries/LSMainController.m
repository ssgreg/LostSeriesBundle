//
//  LSMainController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSShowInfoCollectionViewController.h"
#import "LSShowsFollowingController.h"
#import "LSMainController.h"
#import "LSModelBase.h"
#import <WorkflowLink/WorkflowLink.h>
#import "Logic/LSApplication.h"


//
// LSShowsWaitForDeviceTokenDidRecieveWL
//

@interface LSWLinkBaseWaitForDeviceToken : WFWorkflowLink
@end

@implementation LSWLinkBaseWaitForDeviceToken

- (void) update
{
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(receiveDeviceTokenNotification:)
    name:LSApplicationDeviceTokenDidRecieveNotification
    object:nil];
}

- (void) input
{
  if ([LSApplication singleInstance].deviceToken)
  {
    [self output];
  }
  else
  {
    [self forwardBlock];
  }
}

- (void) receiveDeviceTokenNotification:(NSNotification *)notification
{
  if (!self.isBlocked)
  {
    [self output];
  }
}

@end


//
// LSWLinkBaseGetterShows
//

@protocol LSDataBaseGetterShows <LSShowAsyncBackendFacadeData, LSDataBaseShowsRaw>
@end

@interface LSWLinkBaseGetterShows : WFWorkflowLink
@end

@implementation LSWLinkBaseGetterShows

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseGetterShows);

- (void) input
{
  [self.data.backendFacade getShowInfoArray:^(NSArray* shows)
  {
    if (!self.isBlocked)
    {
      self.data.showsRaw = shows;
      [self output];
    }
  }];
  [self forwardBlock];
}

@end


//
// LSWLinkBaseGetterShowsFavorite
//

@protocol LSDataBaseGetterFavoriteShows <LSShowAsyncBackendFacadeData, LSDataBaseShowsFavoriteRaw>
@end

@interface LSWLinkBaseGetterShowsFavorite : WFWorkflowLink
@end

@implementation LSWLinkBaseGetterShowsFavorite

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseGetterFavoriteShows);

- (void) input
{
  [self.data.backendFacade
    getSubscriptionInfoArrayByDeviceToken:[LSApplication singleInstance].deviceToken
    replyHandler:^(NSArray* infos)
  {
    if (!self.isBlocked)
    {
      self.data.showsFavoriteRaw = infos;
      [self output];
    }
  }];
  [self forwardBlock];
}

@end


//
// LSWLinkBaseConverterRaw
//

@protocol LSDataBaseConverterRaw <LSDataBaseShowsRaw, LSDataBaseShowsFavoriteRaw, LSShowsShowsData, LSShowsFavoriteShowsData>
@end

@interface LSWLinkBaseConverterRaw : WFWorkflowLink
@end

@implementation LSWLinkBaseConverterRaw

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseConverterRaw);

- (void) input
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    // shows
    NSMutableArray* newShowsRaw = [NSMutableArray array];
    for (id show in self.data.showsRaw)
    {
     [newShowsRaw addObject:show];
//     [newShows addObject:show];
//     [newShows addObject:show];
    }

    NSMutableArray* modelsShow = [NSMutableArray array];
    for (id show in newShowsRaw)
    {
     LSShowAlbumCellModel* cellModel = [[LSShowAlbumCellModel alloc] init];
     cellModel.showInfo = show;
     [modelsShow addObject: cellModel];
    }

    // favorite shows
    NSMutableDictionary* modelsShowFavorite = [NSMutableDictionary dictionary];
    for (id info in self.data.showsFavoriteRaw)
    {
      NSUInteger index = [modelsShow indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL* stop)
      {
        return [((LSShowAlbumCellModel*)object).showInfo.originalTitle isEqualToString:((LSSubscriptionInfo*)info).originalTitle];
      }];
      modelsShowFavorite[[NSIndexPath indexPathForRow:index inSection:0]] = [modelsShow objectAtIndex:index];
    }
    //
    dispatch_async(dispatch_get_main_queue(), ^
    {
      if (!self.isBlocked)
      {
        self.data.shows = modelsShow;
        self.data.favoriteShows = modelsShowFavorite;
        [self output];
      }
    });
  });
  [self forwardBlock];
}

@end


//
// LSWLinkBaseLinkerWorkflow
//

@interface LSWLinkBaseLinkerWorkflow : WFWorkflowLink
@end

@implementation LSWLinkBaseLinkerWorkflow
{
  WFWorkflow* theWorkflowShows;
  WFWorkflow* theWorkflowShowsFollowing;
}

- (void) update
{
  [self listenForControllers];
}

- (void) input
{
  [theWorkflowShows input];
  [theWorkflowShowsFollowing input];
}

- (void) block
{
  [theWorkflowShows forwardBlock];
  [theWorkflowShowsFollowing forwardBlock];
}

- (void) onLSShowControllerDidLoadNotification:(NSNotification*)notification
{
  theWorkflowShows = ((LSShowInfoCollectionViewController*)notification.object).workflow;
  theWorkflowShows.nextLink = WFLinkToSelfForward(self);
  // try to start workflow
  if (!self.isBlocked)
  {
    [self input];
  }
}

- (void) onLSShowFollowingControllerDidLoadNotification:(NSNotification*)notification
{
//  theWorkflowShowsFollowing = ((LSShowsFollowingController*)notification.object).workflow;
}

- (void) listenForControllers
{
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onLSShowControllerDidLoadNotification:)
    name:LSShowsControllerDidLoadNotification
    object:nil];
  //
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onLSShowFollowingControllerDidLoadNotification:)
    name:LSShowsFollowingControllerDidLoadNotification
    object:nil];
}

@end



//
// LSMainController
//

@implementation LSMainController
{
  WFWorkflow* theWorkflow;
}

- (void) initInternal
{
  theWorkflow = WFLinkWorkflow(
      WFSplitWorkflowWithOutputUsingAnd(
          WFLinkWorkflow(
              [[LSWLinkBaseWaitForDeviceToken alloc] init]
            , [[LSWLinkBaseGetterShowsFavorite alloc] initWithData:[LSApplication singleInstance].modelBase]
            , nil)
        , [[LSWLinkBaseGetterShows alloc] initWithData:[LSApplication singleInstance].modelBase]
        , nil)
    , [[LSWLinkBaseConverterRaw alloc] initWithData:[LSApplication singleInstance].modelBase]
    , [[LSWLinkBaseLinkerWorkflow alloc] init]
    , nil);
  //
  [theWorkflow input];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [self initInternal];
}

@end