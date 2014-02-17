//
//  LSShowInfoCollectionViewController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 30/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSShowInfoCollectionViewController.h"
#import "Remote/LSBatchArtworkGetter.h"
#import <UIComponents/UILoadingView.h>
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
// LSWLinkShowsCollection
//

@protocol LSDataShowsCollection <LSShowsShowsData, LSShowsFavoriteShowsData, LSShowAsyncBackendFacadeData>
@end

@interface LSWLinkShowsCollection : WFWorkflowLink <LSBatchArtworkGetterDelegate>

- (BOOL) isFavoriteItemAtIndex:(NSIndexPath*)indexPath;
- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) itemsCount;

@end

@implementation LSWLinkShowsCollection
{
  LSBatchArtworkGetter* theArtworkGetter;
}

SYNTHESIZE_WL_ACCESSORS(LSDataShowsCollection, LSViewShowsCollection);

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
  theArtworkGetter = nil;
  [self updateView];
}

- (void) input
{
  [self tryToStartBatchArtworkGetter];
  [self updateView];
  [self output];
}

- (void) updateView
{
  [self.view showCollectionClearSelection];
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
// LSShowCollectionData
//

@protocol LSDataShowsSelection <LSShowsSelectionModeData, LSShowsShowsData, LSShowsSelectedShowsData, LSShowsFavoriteShowsData>
@end

@interface LSWLinkShowsSelection : WFWorkflowLink

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath;
- (void) didDeselectItemAtIndex:(NSIndexPath*)indexPath;
- (BOOL) isItemSelectedAtIndex:(NSIndexPath*)indexPath;

@end

@implementation LSWLinkShowsSelection
{
  NSMutableDictionary* theSelectedShows;
  NSNumber* theIsMultipleSelectedAllowedFlag;
}

SYNTHESIZE_WL_ACCESSORS(LSDataShowsSelection, LSViewShowsSelection);

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath
{
  theSelectedShows[indexPath] = self.data.shows[indexPath.row];
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

- (void) update
{
  theSelectedShows = [NSMutableDictionary dictionary];
  theIsMultipleSelectedAllowedFlag = nil;
  //
  self.data.selectedShows = theSelectedShows;
  [self updateView];
}

- (void) input
{
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
  LSSelectButtonWL* theSelectButtonWL;
  LSWLinkShowsCollection* theShowCollectionWL;
  LSWLinkShowsSelection* theWLinkShowsSelection;
  LSSubscribeButtonWL* theSubscribeButtonWL;
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

- (WFWorkflow*) workflow
{
  return theWorkflow;
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
  theSelectButtonWL = [[LSSelectButtonWL alloc] initWithData:[LSApplication singleInstance].modelBase view:self];
  theShowCollectionWL = [[LSWLinkShowsCollection alloc] initWithData:[LSApplication singleInstance].modelBase view:self];
  theWLinkShowsSelection = [[LSWLinkShowsSelection alloc] initWithData:[LSApplication singleInstance].modelBase view:self];
  theSubscribeButtonWL = [[LSSubscribeButtonWL alloc] initWithData:[LSApplication singleInstance].modelBase view:self];
  theCancelSelectionModeWL = [[LSCancelSelectionModeWL alloc] initWithData:[LSApplication singleInstance].modelBase];
  //
  
  
  theWorkflow = WFSplitWorkflowWithOutputUsingOr(
      WFLinkWorkflow(
        theShowCollectionWL
        , nil)
    , WFLinkWorkflow(
        theSelectButtonWL
      , theWLinkShowsSelection
      , [[LSNavigationBarWL alloc] initWithData:[LSApplication singleInstance].modelBase view:self]
      , theSubscribeButtonWL
      , [[LSSubscribeActionWL alloc] initWithData:[LSApplication singleInstance].modelBase view:self]
      , nil)
    , nil);
  

  self.edgesForExtendedLayout = UIRectEdgeNone;
  
  
  UITabBarItem *item0 = [self.tabBarController.tabBar.items objectAtIndex:0];
  item0.selectedImage = [UIImage imageNamed:@"TVShowsSelectedTabItem"];
  UITabBarItem *item1 = [self.tabBarController.tabBar.items objectAtIndex:1];
  item1.selectedImage = [UIImage imageNamed:@"FavTVShowsSelectedTabItem"];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:LSShowsControllerDidLoadNotification object:self];
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
    [theWLinkShowsSelection didSelectItemAtIndex:indexPath];
    LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
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


//
// Notifications
//

NSString* LSShowsControllerDidLoadNotification = @"LSShowsControllerDidLoadNotification";
