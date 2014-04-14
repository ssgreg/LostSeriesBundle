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
// LSWLinkRefresher
//

@protocol LSDataBaseRefresher <LSDataBaseFacadeAsyncBackend>
@end

@interface LSWLinkBaseRefresher : WFWorkflowLink
@end

@implementation LSWLinkBaseRefresher

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseRefresher);

- (void) doSomething:(NSTimer*)timer
{
//  [self output];
}

- (void) input
{
  [self setTimer];
  [self output];
}

- (void) setTimer
{
  [NSTimer scheduledTimerWithTimeInterval:10
    target:self
    selector:@selector(doSomething:)
    userInfo:nil
    repeats:YES];
}

@end



//
// LSWLinkBaseWaitForDeviceToken
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

@protocol LSDataBaseGetterShows <LSDataBaseFacadeAsyncBackend, LSDataBaseShowsRaw>
@end

@interface LSWLinkBaseGetterShows : WFWorkflowLink
@end

@implementation LSWLinkBaseGetterShows
{
  NSInteger counter;
}

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseGetterShows);

- (void) update
{
  counter = 0;
}

- (void) input
{
  [self.data.backendFacade getShowInfoArray:^(NSArray* shows)
  {
    if (!self.isBlocked)
    {
      NSMutableArray* mutArray = [NSMutableArray arrayWithArray:shows];
      for (NSInteger i = 0; i < counter; ++i)
      {
        [mutArray removeObjectAtIndex:0];
      }
      ++counter;
      self.data.showsRaw = mutArray;
      [self output];
    }
  }];
  [self forwardBlock];
}

@end


//
// LSWLinkBaseGetterShowsFavorite
//

@protocol LSDataBaseGetterFavoriteShows <LSDataBaseFacadeAsyncBackend, LSDataBaseShowsFavoriteRaw>
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

@protocol LSDataBaseConverterRaw <LSDataBaseShowsRaw, LSDataBaseShowsFavoriteRaw, LSDataBaseModelShowsLists>
@end

@interface LSWLinkBaseConverterRaw : WFWorkflowLink
@end

@implementation LSWLinkBaseConverterRaw

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseConverterRaw);

- (void) input
{
  __block NSArray* showsRaw = self.data.showsRaw;
  __block NSArray* favoriteShowsRaw = self.data.showsFavoriteRaw;
  //
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    // shows
    NSMutableArray* modelsShow = [NSMutableArray array];
    for (id show in showsRaw)
    {
     LSShowAlbumCellModel* cellModel = [[LSShowAlbumCellModel alloc] init];
     cellModel.showInfo = show;
     [modelsShow addObject: cellModel];
    }

    
    NSArray* target = [modelsShow sortedArrayUsingComparator:^NSComparisonResult(LSShowAlbumCellModel* left, LSShowAlbumCellModel* right)
    {
      if (!left.showInfo.episodes || !right.showInfo.episodes || left.showInfo.episodes.count == 0 || right.showInfo.episodes.count == 0)
      {
        return NSOrderedSame;
      }
      NSDate* dateLeft = ((LSEpisodeInfo*)left.showInfo.episodes[left.showInfo.episodes.count - 1]).dateTranslate;
      NSDate* dateRight = ((LSEpisodeInfo*)right.showInfo.episodes[right.showInfo.episodes.count - 1]).dateTranslate;
      // sort by last episode date - show with latest episode comes first
      return [dateRight compare:dateLeft];
    }];

    
    LSModelShowsLists* modelShowsLists = [[LSModelShowsLists alloc] initWithShows:target];
    // following shows
    for (id info in favoriteShowsRaw)
    {
      NSUInteger index = [target indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL* stop)
      {
        return [((LSShowAlbumCellModel*)object).showInfo.showID isEqualToString:((LSSubscriptionInfo*)info).showID];
      }];
      if (index != NSNotFound)
      {
        [modelShowsLists.showsFollowing addObjectByIndexSource:index];
      }
    }
    //
    dispatch_async(dispatch_get_main_queue(), ^
    {
      if (!self.isBlocked)
      {
        self.data.modelShowsLists = modelShowsLists;
        [self output];
      }
    });
  });
  [self forwardBlock];
}

@end


//
// LSWLinkBaseArtworkGetter
//

@protocol LSDataBaseArtworkGetter <LSDataBaseShows>
@end

@interface LSWLinkBaseArtworkGetter : WFWorkflowLink <LSClientServiceArtworkGetters>
@end

@implementation LSWLinkBaseArtworkGetter
{
  NSInteger theIndexNext;
}

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseArtworkGetter);

- (void) update
{
  [[LSApplication singleInstance].serviceArtworkGetter addClient:self];
}

- (void) input
{
  // always get all arworks
  theIndexNext = 0;
  [[LSApplication singleInstance].serviceArtworkGetter start];
  [self output];
}

#pragma mark - LSClientServiceArtworkGetters implementation

- (LSServiceArtworkGetterPriority) priorityForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  return LSServiceArtworkGetterPriorityLow;
}

- (NSRange) indexQueueForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  return NSMakeRange(0, self.data.shows.count);
}

- (NSInteger) nextIndexForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  return theIndexNext < self.data.shows.count
    ? theIndexNext++
    : NSNotFound;
}

@end


//
// LSWLinkRouterNavigation
//

@interface LSWLinkRouterNavigation : WFWorkflowLink
- (void) didChangeRouterNavigationWay;
@end

@implementation LSWLinkRouterNavigation
{
  WFWorkflow* theWorkflowShows;
  WFWorkflow* theWorkflowShowsFollowing;
}

SYNTHESIZE_WL_VIEW_ACCESSOR(LSViewRouterNavigation);

- (void) didChangeRouterNavigationWay
{
  [self tryToStartWorkflow];
}

- (void) update
{
  [self listenForControllers];
}

- (void) input
{
  [self.view routerNavigationWay] == LSRouterNavigationWayShows
    ? [theWorkflowShows input]
    : [theWorkflowShowsFollowing input];
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
  [self tryToStartWorkflow];
}

- (void) onLSShowFollowingControllerDidLoadNotification:(NSNotification*)notification
{
  theWorkflowShowsFollowing = ((LSShowsFollowingController*)notification.object).workflow;
  theWorkflowShowsFollowing.nextLink = WFLinkToSelfForward(self);
  [self tryToStartWorkflow];
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

- (void) tryToStartWorkflow
{
  if (!self.isBlocked)
  {
    [self input];
  }
}

@end


//
// LSMainController
//

@implementation LSMainController
{
  WFWorkflow* theWorkflow;
  LSWLinkRouterNavigation* theWLinkRouterNavigation;
}

- (void) initInternal
{
  // set delegate to self to catch tab changing (can't do it in IB)
  self.delegate = self;
  //
  LSModelBase* model = [LSApplication singleInstance].modelBase;
  theWLinkRouterNavigation = [[LSWLinkRouterNavigation alloc] initWithView:self];
  //
  theWorkflow = WFLinkWorkflow(
      [[LSWLinkBaseRefresher alloc] initWithData:model]
    , WFSplitWorkflowWithOutputUsingAnd(
          WFLinkWorkflow(
              [[LSWLinkBaseWaitForDeviceToken alloc] init]
            , [[LSWLinkBaseGetterShowsFavorite alloc] initWithData:model]
            , nil)
        , [[LSWLinkBaseGetterShows alloc] initWithData:model]
        , nil)
    , [[LSWLinkBaseConverterRaw alloc] initWithData:model]
    , [[LSWLinkBaseArtworkGetter alloc] initWithData:model]
    , theWLinkRouterNavigation
    , nil);
   //
  [theWorkflow input];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [self initInternal];
}

#pragma mark - LSViewRouterNavigation

- (LSRouterNavigationWay) routerNavigationWay
{
  return self.selectedIndex == 0
    ? LSRouterNavigationWayShows
    : LSRouterNavigationWayShowsFollowing;
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
  // we should start workflow each time user changes view controller
  [theWLinkRouterNavigation didChangeRouterNavigationWay];
}

@end
