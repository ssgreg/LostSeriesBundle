//
//  LSShowInfoCollectionViewController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 30/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSShowInfoCollectionViewController.h"
#import "Remote/LSAsyncBackendFacade.h"
#import "Remote/LSBatchArtworkGetter.h"
#import "CachingServer/LSCachingServer.h"
#import <UIComponents/UILoadingView.h>
#import <UIComponents/UIStatusBarView.h>
#import <WorkflowLink/WorkflowLink.h>
#import "Logic/LSApplication.h"


@interface LSShowAlbumCellModel : NSObject
@property LSShowInfo* showInfo;
@property UIImage* artwork;
@end


@implementation LSShowAlbumCellModel

+ (LSShowAlbumCellModel*)showAlbumCellModel
{
  return [[LSShowAlbumCellModel alloc] init];
}

@end


@interface LSShowAlbumCell : UICollectionViewCell
@property IBOutlet UIImageView* overlay;
@property IBOutlet UIImageView* image;
@property IBOutlet UIImageView* subscriptionOverlay;
@property IBOutlet UILabel* detail;
@end

@implementation LSShowAlbumCell
@end


//
// Getter protocols
//

@protocol LSShowAsyncBackendFacadeData
@property (readonly) LSAsyncBackendFacade* backendFacade;
@end

@protocol LSShowsSelectionModeData
@property BOOL selectionModeActivated;
@end

@protocol LSShowsShowsData
@property NSArray* shows;
@end

@protocol LSShowsSelectedShowsData
@property NSDictionary* selectedShows;
@end

@protocol LSShowsFavoriteShowsData
@property NSDictionary* favoriteShows;
@end

@protocol LSDataBaseShowsRaw
@property NSArray* showsRaw;
@end

@protocol LSDataBaseShowsFavoriteRaw
@property NSArray* showsFavoriteRaw;
@end


//
// LSShowsWaitForDeviceTokenDidRecieveWL
//

@interface LSShowsWaitForDeviceTokenDidRecieveWL : WFWorkflowLink
@end

@implementation LSShowsWaitForDeviceTokenDidRecieveWL

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
     LSShowAlbumCellModel* cellModel = [LSShowAlbumCellModel showAlbumCellModel];
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
// LSSubscribeActionData
//

@protocol LSSubscribeActionData <LSShowAsyncBackendFacadeData, LSShowsFavoriteShowsData, LSShowsSelectedShowsData>
@end

@interface LSSubscribeActionWL : WFWorkflowLink
@end

@implementation LSSubscribeActionWL

SYNTHESIZE_WL_ACCESSORS(LSSubscribeActionData, LSSubscribeActionView);

- (void) input
{
  [self.view showActionIndicator:YES];
  [self.data.backendFacade subscribeByDeviceToken:[LSApplication singleInstance].deviceToken subscriptionInfo:self.makeSubscriptions replyHandler:^(BOOL result)
  {
    [self.view showActionIndicator:NO];
    result
      ? [self output]
      : [self forwardBlock];
  }];
  //
  NSMutableDictionary* favoriteShows = [NSMutableDictionary dictionaryWithDictionary:self.data.favoriteShows];
  [favoriteShows addEntriesFromDictionary:self.data.selectedShows];
  self.data.favoriteShows = favoriteShows;
  [self output];
}

- (NSArray*) makeSubscriptions
{
  NSMutableArray* subscriptions = [NSMutableArray array];
  [self.data.selectedShows enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL* stop)
  {
    LSSubscriptionInfo* subscription = [[LSSubscriptionInfo alloc] init];
    subscription.originalTitle = ((LSShowAlbumCellModel*)object).showInfo.originalTitle;
    [subscriptions addObject:subscription];
  }];
  return subscriptions;
}

@end


//
// LSSelectButtonData
//

@protocol LSSelectButtonData <LSShowsSelectionModeData>
@end


@interface LSSelectButtonWL : WFWorkflowLink
- (void) clicked;
@end

@implementation LSSelectButtonWL

SYNTHESIZE_WL_ACCESSORS(LSSelectButtonData, LSSelectButtonView);

- (void) update
{
  self.data.selectionModeActivated ? [self.view selectButtonTurnIntoCancel] : [self.view selectButtonTurnIntoSelect];
}

- (void) input
{
  [self.view selectButtonDisable:NO];
  [self update];
  [self output];
}

- (void) block
{
  [self.view selectButtonDisable:YES];
}

- (void) clicked
{
  self.data.selectionModeActivated = !self.data.selectionModeActivated;
  [self input];
}

@end


@interface LSCancelSelectionModeWL : WFWorkflowLink
@end

@implementation LSCancelSelectionModeWL

SYNTHESIZE_WL_DATA_ACCESSOR(LSSelectButtonData);

- (void) input
{
  self.data.selectionModeActivated = NO;
  [self output];
}

@end


//
// LSSubscribeButtonData
//

@protocol LSSubscribeButtonData <LSShowsSelectionModeData, LSShowsSelectedShowsData>
@end


@interface LSSubscribeButtonWL : WFWorkflowLink
- (void) clicked;
@end

@implementation LSSubscribeButtonWL

SYNTHESIZE_WL_ACCESSORS(LSSubscribeButtonData, LSShowSubscribeButtonView);

- (void) update
{
  [self.view showSubscribeButton:self.data.selectionModeActivated];
  [self.view enableSubscribeButton:self.data.selectionModeActivated && self.data.selectedShows.count > 0];
}

- (void) input
{
  [self update];
  [self forwardBlock];
}

- (void) clicked
{
  [self update];
  [self output];
}

@end


//
// LSNavigationBarData
//

@protocol LSNavigationBarData <LSShowsSelectionModeData, LSShowsSelectedShowsData>
@end


@interface LSNavigationBarWL : WFWorkflowLink
@end

@implementation LSNavigationBarWL

SYNTHESIZE_WL_ACCESSORS(LSNavigationBarData, LSNavigationView);

- (void) input
{
  [self.view navigationSetTitle:[self makeTitle]];
  [self output];
}

- (NSString*) makeTitle
{
  NSString* title = @"Lost Series";
  if (self.data.selectionModeActivated)
  {
    NSInteger selectedShowCount = self.data.selectedShows.count;
    title = selectedShowCount == 0
      ? @"Select Items"
      : [NSString stringWithFormat:@"%ld %@ Selected", selectedShowCount, (selectedShowCount == 1 ? @"Show" : @"Shows")];
  }
  return title;
}

@end


//
// LSShowCollectionData
//

@protocol LSShowCollectionData <LSShowsSelectionModeData, LSShowsShowsData, LSShowsSelectedShowsData, LSShowsFavoriteShowsData, LSShowAsyncBackendFacadeData>
@end


@interface LSShowCollectionWL : WFWorkflowLink <LSBatchArtworkGetterDelegate>

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath;
- (void) didDeselectItemAtIndex:(NSIndexPath*)indexPath;
- (BOOL) isItemSelectedAtIndex:(NSIndexPath*)indexPath;
- (BOOL) isFavoriteItemAtIndex:(NSIndexPath*)indexPath;
- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) itemsCount;

@end

@implementation LSShowCollectionWL
{
  NSMutableDictionary* theSelectedShows;
  NSNumber* theIsMultipleSelectedAllowedFlag;
  //
  LSBatchArtworkGetter* theArtworkGetter;
}

SYNTHESIZE_WL_ACCESSORS(LSShowCollectionData, LSShowCollectionView);

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath
{
  theSelectedShows[indexPath] = [self itemAtIndex:indexPath];
  [self input];
}

- (void) didDeselectItemAtIndex:(NSIndexPath*)indexPath
{
  [theSelectedShows removeObjectForKey:indexPath];
  [self input];
}

- (BOOL) isItemSelectedAtIndex:(NSIndexPath*)indexPath
{
  return [theSelectedShows objectForKey:indexPath];
}

- (BOOL) isFavoriteItemAtIndex:(NSIndexPath*)indexPath
{
  return [self.data.favoriteShows objectForKey:indexPath];
}

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath
{
  return self.data.shows[indexPath.row];
}

- (NSUInteger) itemsCount
{
  return self.data.shows.count;
}

- (void) update
{
  theSelectedShows = [NSMutableDictionary dictionary];
  theArtworkGetter = nil;
  theIsMultipleSelectedAllowedFlag = nil;
  //
  self.data.selectedShows = theSelectedShows;
  [self updateView];
}

- (void) input
{
  [self tryToStartBatchArtworkGetter];
  [self tryToUpdateSelectionMode];
  //
  self.data.selectedShows = theSelectedShows;
  [self output];
}

- (void) updateView
{
  [self.view showCollectionAllowMultipleSelection:theIsMultipleSelectedAllowedFlag.boolValue];
  [self.view showCollectionClearSelection];
}

- (void) tryToUpdateSelectionMode
{
  BOOL isSelectionModeChanged = !theIsMultipleSelectedAllowedFlag || self.data.selectionModeActivated != theIsMultipleSelectedAllowedFlag.boolValue;
  if (isSelectionModeChanged)
  {
    theIsMultipleSelectedAllowedFlag = [NSNumber numberWithBool:self.data.selectionModeActivated];
    [theSelectedShows removeAllObjects];
    [self updateView];
  }
}

- (void) tryToStartBatchArtworkGetter
{
  if (!theArtworkGetter)
  {
    theArtworkGetter = [LSBatchArtworkGetter artworkGetterWithDelegate:self];
  }
}

#pragma mark - LSBatchArtworkGetterDelegate implementation

- (NSInteger) getNumberOfItems
{
  return [self itemsCount];
}

- (NSArray*) getPriorityWindow
{
  return [self.view showCollectionVisibleItemIndexs];
}

- (void) getArtworkAsyncForIndex:(NSInteger)index completionHandler:(void (^)(NSData*))handler
{
  LSShowAlbumCellModel* cellModel = [self itemAtIndex:[NSIndexPath indexPathForRow:index inSection:0]];
  [[self.data backendFacade] getArtworkByShowInfo:cellModel.showInfo replyHandler:handler];
}

- (void) didGetArtwork:(NSData*)data forIndex:(NSInteger)index
{
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  // update cache
  LSShowAlbumCellModel* cellModel = [self itemAtIndex:indexPath];
  cellModel.artwork = [UIImage imageWithData:data];
  // update view
  [self.view showCollectionUpdateItemAtIndex:indexPath];
}

@end


//
// LSShowAlbumModel
//

@interface LSShowAlbumModel : NSObject
    < LSDataBaseShowsRaw
    , LSDataBaseShowsFavoriteRaw
    , LSSelectButtonData
    , LSShowCollectionData
    , LSNavigationBarData >

- (id) init;
@property NSDictionary* favoriteShows;

@end

@implementation LSShowAlbumModel
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


@implementation LSShowInfoCollectionViewController
{
  IBOutlet UICollectionView* theCollectionView;
  IBOutlet UIBarButtonItem* theSelectButton;
  IBOutlet UINavigationItem* theNavigationItem;
  // custom views
  UIToolbar* theSubscribeToolbar;
  UIBarButtonItem* theSubscribeButton;
  UILoadingView* theCollectionViewLoadingStub;
  UIStatusBarView* temp;
  UIWindow* myWindow;
  //
  NSArray* theVisibleItemIndexes;
  // workflow
  WFWorkflow* theWorkflow;
  LSShowAlbumModel* theModel;
  LSSelectButtonWL* theSelectButtonWL;
  LSNavigationBarWL* theNavigationBarWL;
  LSShowCollectionWL* theShowCollectionWL;
  LSSubscribeButtonWL* theSubscribeButtonWL;
  LSSubscribeActionWL* theSubscribeActionWL;
  LSCancelSelectionModeWL* theCancelSelectionModeWL;
}

- (IBAction) selectButtonClicked:(id)sender;
{
  [theSelectButtonWL clicked];
}

- (IBAction) subscribeButtonClicked:(id)sender
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Unsubscribe" otherButtonTitles:@"Subscribe", nil];
  [actionSheet showInView:self.tabBarController.view];
}

- (void) doSomething:(NSTimer*)timer
{
  BOOL flag = ((NSNumber*)[timer userInfo]).boolValue;
  
        CGRect tr = myWindow.frame;
      CGRect tr1 = tr;
  
  
  if (flag)
  {
    tr.origin.y = -20;
    myWindow.frame = tr;
    tr.origin.y = 0;
    [myWindow setHidden:NO];

        [myWindow setHidden:NO];
  
  [UIView beginAnimations:@"foo" context:nil];
[UIView setAnimationDuration:0.3];
  myWindow.frame = tr;


    [UIView commitAnimations];

  }
  else
  {
       theCollectionView.window.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(245/255.0) blue:(245/255.0) alpha:1.f];

    CGRect rect = self.navigationController.navigationBar.frame;
    CGRect rect1 = self.view.frame;


  [[UIApplication sharedApplication] setStatusBarHidden:flag withAnimation:UIStatusBarAnimationSlide];

      rect1 = self.navigationController.navigationBar.frame;

    self.navigationController.navigationBar.frame = rect;

  rect1 = self.view.frame;
  rect1.origin.y = rect.origin.y + rect.size.height;
  self.view.frame = rect1;
    
        [myWindow setHidden:YES];

  }
  
 // myWindow.frame = tr;

}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  [self createSubscribeToolbar];
  [self createCollectionViewLoadingStub];
  //
  theModel = [[LSShowAlbumModel alloc] init];
  theSelectButtonWL = [[LSSelectButtonWL alloc] initWithData:theModel view:self];
  theNavigationBarWL = [[LSNavigationBarWL alloc] initWithData:theModel view:self];
  theShowCollectionWL = [[LSShowCollectionWL alloc] initWithData:theModel view:self];
  theSubscribeButtonWL = [[LSSubscribeButtonWL alloc] initWithData:theModel view:self];
  theSubscribeActionWL = [[LSSubscribeActionWL alloc] initWithData:theModel view:self];
  theCancelSelectionModeWL = [[LSCancelSelectionModeWL alloc] initWithData:theModel];
  //
  
  theWorkflow = WFLinkWorkflow(
      WFLinkWorkflowBatchUsingAnd(
          WFLinkWorkflow(
            [[LSShowsWaitForDeviceTokenDidRecieveWL alloc] init]
          , [[LSWLinkBaseGetterShowsFavorite alloc] initWithData:theModel]
          , nil)
        , [[LSWLinkBaseGetterShows alloc] initWithData:theModel]
        , nil)
    , [[LSWLinkBaseConverterRaw alloc] initWithData:theModel]
    , theSelectButtonWL
    , theShowCollectionWL
    , theNavigationBarWL
    , theSubscribeButtonWL
    , theSubscribeActionWL
    , nil);
  

  self.edgesForExtendedLayout = UIRectEdgeNone;
  
  
  UITabBarItem *item0 = [self.tabBarController.tabBar.items objectAtIndex:0];
  item0.selectedImage = [UIImage imageNamed:@"TVShowsSelectedTabItem"];
  UITabBarItem *item1 = [self.tabBarController.tabBar.items objectAtIndex:1];
  item1.selectedImage = [UIImage imageNamed:@"FavTVShowsSelectedTabItem"];
  
  [theWorkflow input];
}

- (void)viewDidAppear:(BOOL)animated
{
  [UIApplication sharedApplication].keyWindow.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(245/255.0) blue:(245/255.0) alpha:1.f];
}

- (void) updateVisibleItemIndexes
{
  NSMutableArray* indexes = [NSMutableArray array];
  NSArray* cells = [theCollectionView visibleCells];
  for (LSShowAlbumCell* cell in cells)
  {
    NSNumber* index = [NSNumber numberWithInteger:[theCollectionView indexPathForCell:cell].row];
    [indexes addObject:index];
  }
  theVisibleItemIndexes = [indexes sortedArrayUsingComparator:^(id obj1, id obj2)
  {
    if ([obj1 integerValue] > [obj2 integerValue])
    {
      return (NSComparisonResult)NSOrderedDescending;
    }
    if ([obj1 integerValue] < [obj2 integerValue])
    {
      return (NSComparisonResult)NSOrderedAscending;
    }
    return (NSComparisonResult)NSOrderedSame;
  }];
}

- (void) updateCell:(LSShowAlbumCell*)cell forIndexPath:(NSIndexPath*)indexPath
{
  LSShowAlbumCellModel* model = [theShowCollectionWL itemAtIndex:indexPath];
  //text
  cell.detail.text = model.showInfo.title;
  //
  if (model.artwork)
  {
    cell.image.image = model.artwork;
    cell.detail.hidden = YES;
  }
  else
  {
    cell.image.image = [UIImage imageNamed:@"StubTVShowImage"];
    cell.detail.hidden = NO;
  }
  //
  if ([theShowCollectionWL isItemSelectedAtIndex:indexPath])
  {
    cell.image.alpha = 0.66;
    cell.overlay.hidden = NO;
  }
  else
  {
    cell.image.alpha = 1;
    cell.overlay.hidden = YES;
  }
  //
  if ([theShowCollectionWL isFavoriteItemAtIndex:indexPath])
  {
    cell.subscriptionOverlay.hidden = NO;
  }
  else
  {
    cell.subscriptionOverlay.hidden = YES;
  }
}

- (void) createSubscribeToolbar
{
  UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  theSubscribeButton = [[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStylePlain target:self action:@selector(subscribeButtonClicked:)];
  NSArray *buttons = [NSArray arrayWithObjects:flexibleItem, theSubscribeButton, flexibleItem, nil];
  //
  CGRect optimalRect = self.tabBarController.tabBar.frame;
//  optimalRect.size.height -= 5;
//  optimalRect.origin.y += 5;
  //
//  optimalRect = CGRectMake(0, 0, 320, 40);
  theSubscribeToolbar = [[UIToolbar alloc] initWithFrame:optimalRect];
  [theSubscribeToolbar setItems:buttons animated:NO];
  theSubscribeToolbar.hidden = YES;
//  [self.view addSubview:theSubscribeToolbar];
    [self.tabBarController.tabBar.window.viewForBaselineLayout addSubview:theSubscribeToolbar];

}

- (void) createCollectionViewLoadingStub
{
  CGRect rect = theCollectionView.frame;
  // fix frame due the reason that frame takes height of tab bar and navigation bar
  rect.size.height -= self.tabBarController.tabBar.frame.size.height;
  rect.size.height -= self.navigationController.navigationBar.frame.size.height;
  //
  theCollectionViewLoadingStub = [[UILoadingView alloc] initWithFrame:rect];
  [theCollectionViewLoadingStub setText:@"Loading..."];
  [theCollectionView.viewForBaselineLayout addSubview:theCollectionViewLoadingStub];
  theCollectionViewLoadingStub.hidden = YES;

  
  
  CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
  CGRect winFrame = statusBarFrame;
  winFrame.origin.y = -winFrame.size.height;
  myWindow = [[UIWindow alloc] initWithFrame:winFrame];
  [myWindow setWindowLevel:UIWindowLevelStatusBar+1];
  [myWindow makeKeyAndVisible];
  
  temp = [[UIStatusBarView alloc] initWithFrame:statusBarFrame];
  [temp setText:@"Changing subscription..."];
  [myWindow.viewForBaselineLayout addSubview:temp];
  [myWindow setHidden:YES];
}

#pragma mark - UICollectionViewDataSource implementationr


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  NSUInteger itemCount = [theShowCollectionWL itemsCount];
  theCollectionViewLoadingStub.hidden = itemCount > 0;
  return itemCount;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self updateVisibleItemIndexes];
  //
  LSShowAlbumCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"theCell" forIndexPath:indexPath];
  [self updateCell:cell forIndexPath:indexPath];
  return cell;
}


#pragma mark - UICollectionViewDelegate implementation


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (theCollectionView.allowsMultipleSelection)
  {
    [theShowCollectionWL didSelectItemAtIndex:indexPath];
    LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (theCollectionView.allowsMultipleSelection)
  {
    [theShowCollectionWL didDeselectItemAtIndex:indexPath];
    LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
  }
}


#pragma mark - UIActionSheetDelegate implementation


- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 0)
  {
    [theSubscribeButtonWL clicked];
  }
}


- (void) selectButtonTurnIntoSelect
{
  theSelectButton.title = @"Select";
  theSelectButton.style = UIBarButtonItemStylePlain;
}

- (void) selectButtonTurnIntoCancel
{
  theSelectButton.title = @"Cancel";
  theSelectButton.style = UIBarButtonItemStyleDone;
}

- (void) selectButtonDisable:(BOOL)flag
{
  theSelectButton.enabled = !flag;
}

- (void) navigationSetTitle:(NSString*)title
{
  theNavigationItem.title = title;
}

- (void) showCollectionClearSelection
{
  [theCollectionView reloadData];
}

- (void) showCollectionAllowMultipleSelection:(BOOL)flag
{
  theCollectionView.allowsMultipleSelection = flag;
}

- (void) showCollectionUpdateItemAtIndex:(NSIndexPath*)indexPath
{
  LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
  if (cell)
  {
    [self updateCell:cell forIndexPath:indexPath];
    [cell setNeedsLayout];
  }
}

- (NSArray*) showCollectionVisibleItemIndexs
{
  return theVisibleItemIndexes;
}

- (void) enableSubscribeButton:(BOOL)flag
{
  theSubscribeButton.enabled = flag;
}

- (void) showSubscribeButton:(BOOL)flag
{
  theSubscribeToolbar.hidden = !flag;
  self.tabBarController.tabBar.hidden = flag;
  
//  CGRect collectionViewFrame = theCollectionView.frame;
//  collectionViewFrame.size.height = flag ? theSubscribeToolbar.frame.origin.y - collectionViewFrame.origin.y : self.tabBarController.tabBar.frame.origin.y - collectionViewFrame.origin.y;
//  theCollectionView.frame = collectionViewFrame;
}

- (void) showActionIndicator:(BOOL)flag
{
  if (flag)
  {
       theCollectionView.window.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(245/255.0) blue:(245/255.0) alpha:1.f];

    CGRect rect = self.navigationController.navigationBar.frame;
    CGRect rect1 = self.view.frame;


  [[UIApplication sharedApplication] setStatusBarHidden:flag withAnimation:UIStatusBarAnimationSlide];

      rect1 = self.navigationController.navigationBar.frame;

    self.navigationController.navigationBar.frame = rect;

  rect1 = self.view.frame;
  rect1.origin.y = rect.origin.y + rect.size.height;
  self.view.frame = rect1;

  }
  else
  {
          CGRect tr = myWindow.frame;
      CGRect tr1 = tr;
  
    tr.origin.y = -20;
  
  [UIView beginAnimations:@"foo" context:nil];
[UIView setAnimationDuration:0.3];
  myWindow.frame = tr;


    [UIView commitAnimations];

  }

  [NSTimer scheduledTimerWithTimeInterval:0.3
    target:self
    selector:@selector(doSomething:)
    userInfo:[NSNumber numberWithBool:flag]
    repeats:NO];
}

@end
