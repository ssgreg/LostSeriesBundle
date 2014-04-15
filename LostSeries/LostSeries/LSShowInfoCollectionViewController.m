//
//  LSShowInfoCollectionViewController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 30/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSShowInfoCollectionViewController.h"
#import "LSControllerShowDetails.h"
#import <UIComponents/UIStatusBarView.h>
#import "LSModelBase.h"
#import "Logic/LSApplication.h"


//
// LSShowAlbumCell
//

@interface LSShowAlbumCell : UICollectionViewCell
@property IBOutlet UIImageView* overlay;
@property IBOutlet UIImageView* image;
@property IBOutlet UIImageView* subscriptionOverlay;
@property IBOutlet UILabel* detail;
@end

@implementation LSShowAlbumCell
@end


//
// LSWLinkProxyController
//

@protocol LSDataProxyController <LSDataBaseShows, LSDataBaseModelShowForDatails>
@end

@interface LSWLinkProxyController : WFWorkflowLink
@end

@implementation LSWLinkProxyController

SYNTHESIZE_WL_ACCESSORS(LSDataProxyController, LSViewSwitcherShowDetails);

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath
{
  self.data.showForDetails = self.data.showsSorted[indexPath.row];
  //
  [self.view switchToController:@"LSShowInfoCollectionViewController.ShowDetails"];
  [self input];
}

- (void) input
{
  LSRegistryControllers* registry = [LSApplication singleInstance].registryControllers;
  LSControllerShowDetails* controller = [registry findControllerByIdentifier:@"LSShowInfoCollectionViewController.ShowDetails"];
  [controller.workflow input];
}

@end


//
// LSWLinkActionChangeFollowingShows
//

@protocol LSDataActionChangeFollowingShows <LSDataBaseFacadeAsyncBackend, LSDataBaseShowsFollowing, LSDataBaseShowsSelected, LSDataBaseModeFollowing>
@end

@interface LSWLinkActionChangeFollowingShows : WFWorkflowLink
@end

@implementation LSWLinkActionChangeFollowingShows

SYNTHESIZE_WL_ACCESSORS(LSDataActionChangeFollowingShows, LSSubscribeActionView);

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
  [self.view showActionIndicator:YES];
  [self.data.backendFacade subscribeByDeviceToken:[LSApplication singleInstance].deviceToken subscriptionInfo:self.makeSubscriptions replyHandler:^(BOOL result)
  {
    [self.view showActionIndicator:NO];
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
  for (LSShowAlbumCellModel* model in self.data.showsFollowing)
  {
    LSSubscriptionInfo* subscription = [[LSSubscriptionInfo alloc] init];
    subscription.showID = model.showInfo.showID;
    //
    [subscriptions addObject:subscription];
  }
  return subscriptions;
}

@end


//
// LSSelectButtonData
//

@protocol LSSelectButtonData <LSDataBaseModeSelection>
@end


@interface LSSelectButtonWL : WFWorkflowLink
- (void) clicked;
@end

@implementation LSSelectButtonWL

SYNTHESIZE_WL_ACCESSORS(LSSelectButtonData, LSSelectButtonView);

- (void) update
{
  self.data.selectionModeActivated
    ? [self.view selectButtonTurnIntoCancel]
    : [self.view selectButtonTurnIntoSelect];
  //
  [self.view selectButtonDisable:[self isBlocked]];
}

- (void) input
{
  [self update];
  [self output];
}

- (void) block
{
  [self update];
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

@protocol LSSubscribeButtonData <LSDataBaseModeSelection, LSDataBaseShowsSelected, LSDataBaseModeFollowing>
@end


@interface LSSubscribeButtonWL : WFWorkflowLink
- (void) follow;
- (void) unfollow;
@end

@implementation LSSubscribeButtonWL

SYNTHESIZE_WL_ACCESSORS(LSSubscribeButtonData, LSShowSubscribeButtonView);

- (void) update
{
  [self.view showSubscribeButton:self.data.selectionModeActivated];
  [self.view enableSubscribeButton:self.data.selectionModeActivated && self.data.showsSelected.count > 0];
}

- (void) input
{
  [self update];
  [self forwardBlock];
}

- (void) follow
{
  self.data.followingModeFollow = YES;
  [self update];
  [self output];
}

- (void) unfollow
{
  self.data.followingModeFollow = NO;
  [self update];
  [self output];
}

@end


//
// LSNavigationBarData
//

@protocol LSNavigationBarData <LSDataBaseModeSelection, LSDataBaseShowsSelected>
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
    NSInteger selectedShowCount = self.data.showsSelected.count;
    title = selectedShowCount == 0
      ? @"Select Items"
      : [NSString stringWithFormat:@"%ld %@ Selected", (long)selectedShowCount, (selectedShowCount == 1 ? @"Show" : @"Shows")];
  }
  return title;
}

@end


//
// LSWLinkShowsCollection
//

@interface LSWLinkShowsCollection : WFWorkflowLink <LSClientServiceArtworkGetters>

- (BOOL) isFavoriteItemAtIndex:(NSIndexPath*)indexPath;
- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) itemsCount;

- (void) filterByString:(NSString*)filter;

@end

@implementation LSWLinkShowsCollection
{
  NSRange theRangeVisibleItems;
  NSInteger theIndexNext;
  //
  NSString* theTextFilter;
}

SYNTHESIZE_WL_ACCESSORS(LSDataBaseModelShowsLists, LSViewShowsCollection);

- (BOOL) isFavoriteItemAtIndex:(NSIndexPath*)indexPath
{
  return [self.data.modelShowsLists.showsFollowing hasIndexSource:indexPath.row];
}

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath
{
  return self.data.modelShowsLists.showsSorted[indexPath.row];
}

- (NSUInteger) itemsCount
{
  return self.data.modelShowsLists.showsSorted.count;
}

- (void) update
{
//  [self updateView];
  //
  theRangeVisibleItems = NSMakeRange(0, 0);
  theIndexNext = NSNotFound;
  [[LSApplication singleInstance].serviceArtworkGetter addClient:self];
}

- (void) input
{
  [self filterByString: theTextFilter];
  [self output];
}

- (void) updateView
{
  [self.view showCollectionReloadData];
}

- (void) filterByString:(NSString*)text
{
  if (text.length)
  {
    self.data.modelShowsLists.showsSorted = [self.data.modelShowsLists makeEmptyArrayPartial];
    for (NSInteger index = 0; index < self.data.modelShowsLists.shows.count; ++index)
    {
      LSShowAlbumCellModel* show = self.data.modelShowsLists.shows[index];
      if ([show.showInfo.title rangeOfString:text].location != NSNotFound)
      {
        [self.data.modelShowsLists.showsSorted addObjectByIndexSource:index];
      }
    }
  }
  else
  {
    self.data.modelShowsLists.showsSorted = self.data.modelShowsLists.shows;
  }
  theTextFilter = text;
  [self updateView];
}


#pragma mark - LSBatchArtworkGetterDelegate implementation


- (LSServiceArtworkGetterPriority) priorityForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  return [self.view showCollectionIsActive] ? LSServiceArtworkGetterPriorityHigh : LSServiceArtworkGetterPriorityNormal;
}

- (NSInteger) nextIndexForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  NSRange newRange = [self.view showCollectionVisibleItemRange];
  if (!NSEqualRanges(theRangeVisibleItems, newRange))
  {
    theRangeVisibleItems = newRange;
    theIndexNext = theRangeVisibleItems.location;
  }
  return NSLocationInRange(theIndexNext, theRangeVisibleItems)
    ? theIndexNext++
    : NSNotFound;
}

- (void) serviceArtworkGetter:(LSServiceArtworkGetter*)service didGetArtworkAtIndex:(NSInteger)index
{
  [self.view showCollectionUpdateItemAtIndex:[NSIndexPath indexPathForRow:index inSection:0]];
}

@end


//
// LSWLinkShowsSelection
//

@protocol LSDataShowsSelection <LSDataBaseModeSelection, LSDataBaseShows, LSDataBaseShowsSelected>
@end

@interface LSWLinkShowsSelection : WFWorkflowLink

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath;
- (void) didDeselectItemAtIndex:(NSIndexPath*)indexPath;
- (BOOL) isItemSelectedAtIndex:(NSIndexPath*)indexPath;

@end

@implementation LSWLinkShowsSelection
{
  NSNumber* theIsMultipleSelectedAllowedFlag;
}

SYNTHESIZE_WL_ACCESSORS(LSDataShowsSelection, LSViewShowsSelection);

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath
{
  [self.data.showsSelected addObjectByIndexSource:indexPath.row];
  [self output];
}

- (void) didDeselectItemAtIndex:(NSIndexPath*)indexPath
{
  [self.data.showsSelected removeObjectByIndexSource:indexPath.row];
  [self output];
}

- (BOOL) isItemSelectedAtIndex:(NSIndexPath*)indexPath
{
  return [self.data.showsSelected hasIndexSource:indexPath.row];
}

- (void) update
{
  theIsMultipleSelectedAllowedFlag = nil;
  [self updateView];
}

- (void) input
{
  // TODO: check selection diff
  [self tryToUpdateSelectionMode];
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
    [self.data.showsSelected removeAllObjectes];
    [self updateView];
  }
}

@end


//
// LSShowInfoCollectionViewController
//

@implementation LSShowInfoCollectionViewController
{
  IBOutlet UICollectionView* theCollectionView;
  IBOutlet UIBarButtonItem* theSelectButton;
  IBOutlet UINavigationItem* theNavigationItem;
  // custom views
  UIToolbar* theSubscribeToolbar;
  UIBarButtonItem* theSubscribeButton;
  // workflow
  WFWorkflow* theWorkflow;
  LSSelectButtonWL* theSelectButtonWL;
  LSWLinkShowsCollection* theShowCollectionWL;
  LSWLinkShowsSelection* theWLinkShowsSelection;
  LSWLinkProxyController* theWLinkProxyController;
  LSSubscribeButtonWL* theSubscribeButtonWL;
  LSCancelSelectionModeWL* theCancelSelectionModeWL;
  //
  LSMessageMBH* theMessageSubscribing;
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

- (WFWorkflow*) workflow
{
  return theWorkflow;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
//  self.edgesForExtendedLayout = UIRectEdgeNone;
  
  
  UITabBarItem *item0 = [self.tabBarController.tabBar.items objectAtIndex:0];
  item0.selectedImage = [UIImage imageNamed:@"TVShowsSelectedTabItem"];
  UITabBarItem *item1 = [self.tabBarController.tabBar.items objectAtIndex:1];
  item1.selectedImage = [UIImage imageNamed:@"FavTVShowsSelectedTabItem"];

  //
  [self createSubscribeToolbar];
  //
  LSModelBase* model = [LSApplication singleInstance].modelBase;
  //
  theSelectButtonWL = [[LSSelectButtonWL alloc] initWithData:model view:self];
  theShowCollectionWL = [[LSWLinkShowsCollection alloc] initWithData:model view:self];
  theWLinkShowsSelection = [[LSWLinkShowsSelection alloc] initWithData:model view:self];
  theWLinkProxyController = [[LSWLinkProxyController alloc] initWithData:model view:self];
  theSubscribeButtonWL = [[LSSubscribeButtonWL alloc] initWithData:model view:self];
  theCancelSelectionModeWL = [[LSCancelSelectionModeWL alloc] initWithData:model];
  //
  
  theWorkflow = WFSplitWorkflowWithOutputUsingOr(
      WFLinkWorkflow(
          theShowCollectionWL
        , nil)
    , WFLinkWorkflow(
          WFLinkRingWorkflow(
              theSelectButtonWL
            , theWLinkShowsSelection
            , WFSplitWorkflowWithOutputUsingOr(
                  theWLinkProxyController
                , WFLinkWorkflow(
                      [[LSNavigationBarWL alloc] initWithData:[LSApplication singleInstance].modelBase view:self]
                    , theSubscribeButtonWL
                    , theCancelSelectionModeWL
                    , nil)
                , nil)
            , nil)
        , [[LSWLinkActionChangeFollowingShows alloc] initWithData:[LSApplication singleInstance].modelBase view:self]
        , nil)
    , nil);
  
  [[NSNotificationCenter defaultCenter] postNotificationName:LSShowsControllerDidLoadNotification object:self];
}

- (void) searchBarTextDidChange:(NSString*)text
{
  [theShowCollectionWL filterByString:text];
}

- (void) viewDidAppear:(BOOL)animated
{
//  [UIApplication sharedApplication].keyWindow.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(245/255.0) blue:(245/255.0) alpha:1.f];
  [super viewDidAppear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  LSControllerShowDetails* controller = segue.destinationViewController;
  controller.idController = segue.identifier;
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
  if ([theWLinkShowsSelection isItemSelectedAtIndex:indexPath])
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


#pragma mark - UICollectionViewDataSource implementationr


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  NSUInteger itemCount = [theShowCollectionWL itemsCount];
  return itemCount;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  LSShowAlbumCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"theCell" forIndexPath:indexPath];
  [self updateCell:cell forIndexPath:indexPath];
  return cell;
}


#pragma mark - UICollectionViewDelegate implementation


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (theCollectionView.allowsMultipleSelection)
  {
    [theWLinkShowsSelection didSelectItemAtIndex:indexPath];
    LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
  }
  else
  {
    [theWLinkProxyController didSelectItemAtIndex:indexPath];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (theCollectionView.allowsMultipleSelection)
  {
    [theWLinkShowsSelection didDeselectItemAtIndex:indexPath];
    LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
  }
}


#pragma mark - UIActionSheetDelegate implementation


- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 1)
  {
    [theSubscribeButtonWL follow];
  }
  else if (buttonIndex == 0)
  {
    [theSubscribeButtonWL unfollow];
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

- (void) showCollectionReloadData
{
  [self reloadData];
}

- (void) showCollectionClearSelection
{
  [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
}

- (void) showCollectionAllowMultipleSelection:(BOOL)flag
{
  theCollectionView.allowsMultipleSelection = flag;
}

- (BOOL) showCollectionIsActive
{
  return self.tabBarController.selectedIndex == 0;
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

- (NSRange) showCollectionVisibleItemRange
{
  return [self rangeVisibleItems];
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
    theMessageSubscribing = [[LSApplication singleInstance].messageBlackHole queueManagedNotification:@"Following new shows..." delay:3.];
  }
  else
  {
    [[LSApplication singleInstance].messageBlackHole closeMessage:theMessageSubscribing];
  }
}

- (void) switchToController:(NSString*)identifier
{
  [self performSegueWithIdentifier:identifier sender:self];
}

@end


//
// Notifications
//

NSString* LSShowsControllerDidLoadNotification = @"LSShowsControllerDidLoadNotification";
