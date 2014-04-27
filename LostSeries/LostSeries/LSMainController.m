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

@interface LSWLinkBaseGetterShowsFavorite : WFWorkflowLink
@end
@implementation LSWLinkBaseGetterShowsFavorite

SYNTHESIZE_WL_DATA_ACCESSOR_NEW(LSModelBase);

- (void) input
{
  [self.data.backendFacade getSubscriptionInfoArrayByCDID:[LSApplication singleInstance].cdid replyHandler:^(NSArray* infos)
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
// LSWLinkBaseGetterUnwatchedEpisodes
//

@interface LSWLinkBaseGetterUnwatchedEpisodes : WFWorkflowLink
@end
@implementation LSWLinkBaseGetterUnwatchedEpisodes

SYNTHESIZE_WL_DATA_ACCESSOR_NEW(LSModelBase);

- (void) input
{
  [self.data.backendFacade getUnwatchedEpisodesInfoArrayByCDID:[LSApplication singleInstance].cdid replyHandler:^(NSArray* infos)
  {
    if (!self.isBlocked)
    {
      self.data.episodesUnwatchedRaw = infos;
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

- (NSArray*) sortByLastEpisodeTime:(NSArray*)source
{
  return [source sortedArrayUsingComparator:^NSComparisonResult(LSShowAlbumCellModel* left, LSShowAlbumCellModel* right)
  {
    if (!left.showInfo.episodes || !right.showInfo.episodes || left.showInfo.episodes.count == 0 || right.showInfo.episodes.count == 0)
    {
      return NSOrderedSame;
    }
    NSDate* dateLeft = ((LSEpisodeInfo*)left.showInfo.episodes[left.showInfo.episodes.count - 1]).dateTranslate;
    NSDate* dateRight = ((LSEpisodeInfo*)right.showInfo.episodes[right.showInfo.episodes.count - 1]).dateTranslate;
    //
    return [dateRight compare:dateLeft];
  }];
}

- (NSArray*) convertToModels:(NSArray*)showsRaw
{
  NSMutableArray* models = [NSMutableArray array];
  for (id show in showsRaw)
  {
   LSShowAlbumCellModel* cellModel = [[LSShowAlbumCellModel alloc] init];
   cellModel.showInfo = show;
   //
   [models addObject:cellModel];
  }
  return models;
}

- (void) input
{
  __block NSArray* showsRaw = self.data.showsRaw;
  __block NSArray* showsFavoriteRaw = self.data.showsFavoriteRaw;
  //
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    NSArray* models = [self sortByLastEpisodeTime:[self convertToModels:showsRaw]];
    //
    LSModelShowsLists* modelShowsLists = [[LSModelShowsLists alloc] initWithShows:models];
    for (LSSubscriptionInfo* info in showsFavoriteRaw)
    {
      NSUInteger index = [models indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL* stop)
      {
        return [((LSShowAlbumCellModel*)object).showInfo.showID isEqualToString:info.showID];
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
- (void) didRegisterWorkflowShows:(WFWorkflow*)workflow;
- (void) didRegisterWorkflowShowsFollowing:(WFWorkflow*)workflow;
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

- (void) didRegisterWorkflowShows:(WFWorkflow*)workflow
{
  theWorkflowShows = workflow;
  theWorkflowShows.nextLink = WFLinkToSelfForward(self);
  [self tryToStartWorkflow];
}

- (void) didRegisterWorkflowShowsFollowing:(WFWorkflow*)workflow
{
  theWorkflowShowsFollowing = workflow;
  theWorkflowShowsFollowing.nextLink = WFLinkToSelfForward(self);
  [self tryToStartWorkflow];
}

- (void) update
{
  [self listenToChangesInModel];
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

- (void) onLSModelBaseDidChange:(NSNotification*)notification
{
  NSLog(@"Starting workflow due to the model changing...");
  [self tryToStartWorkflow];
}

- (void) listenToChangesInModel
{
  [[NSNotificationCenter defaultCenter]
    addObserverForName:LSModelBaseDidChange
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification* notification)
  {
    [self onLSModelBaseDidChange:notification];
  }];
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
  [self listenToControllers];
  [self.workflow input];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [self initInternal];
}

- (void) listenToControllers
{
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onLSShowInfoCollectionViewControllerDidRegister:)
    name:MakeIdController(self.idController, LSShowInfoCollectionViewControllerShortID)
    object:nil];
  //
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onLSShowsFollowingController:)
    name:MakeIdController(self.idController, LSShowsFollowingControllerShortID)
    object:nil];
}

- (void) onLSShowInfoCollectionViewControllerDidRegister:(NSNotification*)notification
{
  [theWLinkRouterNavigation didRegisterWorkflowShows:((id<LSBaseController>)notification.object).workflow];
}

- (void) onLSShowsFollowingController:(NSNotification*)notification
{
  [theWLinkRouterNavigation didRegisterWorkflowShowsFollowing:((id<LSBaseController>)notification.object).workflow];
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


#pragma mark - LSBaseController


- (NSString*) idController
{
  return self.idControllerShort;
}

- (void) setIdController:(NSString*)idController
{
}

- (NSString*) idControllerShort
{
  return LSMainControllerShortID;
}

- (WFWorkflow*) workflow
{
  if (theWorkflow)
  {
    return theWorkflow;
  }
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
            , [[LSWLinkBaseGetterUnwatchedEpisodes alloc] initWithData:model]
            , nil)
        , [[LSWLinkBaseGetterShows alloc] initWithData:model]
        , nil)
    , [[LSWLinkBaseConverterRaw alloc] initWithData:model]
    , [[LSWLinkBaseArtworkGetter alloc] initWithData:model]
    , theWLinkRouterNavigation
    , nil);
   //
  return theWorkflow;
}

@end


NSString* LSMainControllerShortID = @"LSMainController";
