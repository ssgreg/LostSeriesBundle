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
#import <WorkflowLink/WorkflowLink.h>


@interface LSShowAlbumCellModel : NSObject

@property LSShowInfo* showInfo;
@property UIImage* artwork;

@end


@implementation LSShowAlbumCellModel

@synthesize showInfo = theShowInfo;
@synthesize artwork = theArtwork;

+ (LSShowAlbumCellModel*)showAlbumCellModel
{
  return [[LSShowAlbumCellModel alloc] init];
}

@end


@interface LSShowAlbumCell : UICollectionViewCell

@property IBOutlet UIImageView* overlay;
@property IBOutlet UIImageView* image;
@property IBOutlet UILabel* detail;

@end

@implementation LSShowAlbumCell

@synthesize image = theImage;
@synthesize detail = theDetail;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
  }
  return self;
}

@end


//
// Getter protocols
//

@protocol LSShowsSelectionModeData
@property (readonly) BOOL selectionModeActivated;
@end


@protocol LSShowAsyncBackendFacadeData
@property (readonly) LSAsyncBackendFacade* backendFacade;
@end


@protocol LSShowsShowsData
@property (readonly) NSArray* shows;
@end

@protocol LSShowsSelectedShowsData
@property (readonly) NSDictionary* selectedShows;
@end


//
// LSLoadShowActionData
//

@protocol LSLoadShowActionData <LSShowAsyncBackendFacadeData, LSShowsShowsData>
@property NSArray* shows;
@end


@interface LSLoadShowActionWL : WFWorkflowLink
@end


@implementation LSLoadShowActionWL

SYNTHESIZE_WL_DATA_ACCESSOR(LSLoadShowActionData);

- (void) input
{
  [self.data.backendFacade getShowInfoArray:^(NSArray* shows)
  {
    NSMutableArray* newShows = [NSMutableArray array];
    for (id show in shows)
    {
     [newShows addObject:show];
     [newShows addObject:show];
     [newShows addObject:show];
    }

    NSMutableArray* showModels = [NSMutableArray array];
    for (id show in newShows)
    {
     LSShowAlbumCellModel* cellModel = [LSShowAlbumCellModel showAlbumCellModel];
     cellModel.showInfo = show;
     [showModels addObject: cellModel];
    }
    self.data.shows = showModels;
    [self output];
  }];
  [self forwardBlock];
}

@end


//
// LSSubscribeActionData
//

@protocol LSSubscribeActionData <LSShowAsyncBackendFacadeData, LSShowsSelectedShowsData>
@end


@interface LSSubscribeActionWL : WFWorkflowLink
@end


@implementation LSSubscribeActionWL

SYNTHESIZE_WL_ACCESSORS(LSSubscribeActionData, LSSubscribeActionView);

- (void) input
{
  [self.view showActionIndicator:YES];
  [self.data.backendFacade subscribeBySubscriptionInfo:self.makeSubscriptions replyHandler:^()
  {
    [self.view showActionIndicator:NO];
    [self output];
  }];
  [self forwardBlock];
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
@property BOOL selectionModeActivated;
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
  [self output];
}

- (void) block
{
  [self.view selectButtonDisable:YES];
}

- (void) clicked
{
  self.data.selectionModeActivated = !self.data.selectionModeActivated;
  [self update];
  [self input];
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

@protocol LSShowCollectionData <LSShowsSelectionModeData, LSShowsShowsData, LSShowAsyncBackendFacadeData>
@property NSDictionary* selectedShows;
@end


@interface LSShowCollectionWL : WFWorkflowLink <LSBatchArtworkGetterDelegate>

- (void) didSelectItemAtIndex:(NSIndexPath*)indexPath;
- (void) didDeselectItemAtIndex:(NSIndexPath*)indexPath;
- (BOOL) isItemSelectedAtIndex:(NSIndexPath*)indexPath;
- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) itemsCount;

@end

@interface LSShowCollectionWL ()
{
  NSMutableDictionary* theSelectedShows;
  NSNumber* theIsMultipleSelectedAllowedFlag;
  //
  LSBatchArtworkGetter* theArtworkGetter;
}

- (void) updateView;
- (void) tryToUpdateSelectionMode;
- (void) tryToStartBatchArtworkGetter;

@end

@implementation LSShowCollectionWL

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

@interface LSShowAlbumModel : NSObject<LSLoadShowActionData, LSSelectButtonData, LSShowCollectionData, LSNavigationBarData>

- (id) init;

@end

@interface LSShowAlbumModel ()
{
  LSCachingServer* theCachingServer;
  LSAsyncBackendFacade* theBackendFacade;
  //
  BOOL theSelectionModeFlag;
  NSArray* theShows;
  NSDictionary* theSelectedShows;
}
@end

@implementation LSShowAlbumModel

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

@synthesize shows = theShows;
@synthesize selectedShows = theSelectedShows;
@synthesize selectionModeActivated = theSelectionModeFlag;
@synthesize backendFacade = theBackendFacade;

@end



@interface UIStatusBarView : UIView
- (void) setText:(NSString*)text;
@end

@interface UIStatusBarView ()
{
  UILabel* theLabel;
}
@end

@implementation UIStatusBarView

- (id)initWithFrame:(CGRect)frame
{
  if (!(self = [super initWithFrame:frame]))
  {
    return nil;
  }
  theLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  theLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
  theLabel.adjustsFontSizeToFitWidth = YES;
  //
  [self addSubview: theLabel];
  [self setBackgroundColor:[UIColor colorWithRed:(65/255.0) green:(95/255.0) blue:(127/255.0) alpha:1.f]];
  theLabel.textColor = [UIColor whiteColor];
  [self setText:nil];
  //
  return self;
}


- (void) setText:(NSString*)text
{
  // label
  theLabel.text = text;
  [theLabel sizeToFit];
  theLabel.center = self.center;
}

@end


//
// LSShowInfoCollectionViewController
//

@interface LSShowInfoCollectionViewController ()
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
  LSShowAlbumModel* theModel;
  WFWorkflow* theWorkflow;
  LSLoadShowActionWL* theLoadShowActionWL;
  LSSelectButtonWL* theSelectButtonWL;
  LSNavigationBarWL* theNavigationBarWL;
  LSShowCollectionWL* theShowCollectionWL;
  LSSubscribeButtonWL* theSubscribeButtonWL;
  LSSubscribeActionWL* theSubscribeActionWL;
}

- (void) updateVisibleItemIndexes;
- (void) updateCell:(LSShowAlbumCell*)cell forIndexPath:(NSIndexPath*)indexPath;
- (void) createSubscribeToolbar;
- (void) createCollectionViewLoadingStub;

- (void) doSomething:(NSNotification*)notification;
@end

@implementation LSShowInfoCollectionViewController

- (IBAction) selectButtonClicked:(id)sender;
{
  [theSelectButtonWL clicked];
}

- (IBAction) subscribeButtonClicked:(id)sender
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Subscribe", nil];
  [actionSheet showInView:self.view];
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
  [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(doSomething:)
                                             name:UIApplicationWillChangeStatusBarOrientationNotification
                                           object:nil];
  //
  [self createSubscribeToolbar];
  [self createCollectionViewLoadingStub];
  //
  theModel = [[LSShowAlbumModel alloc] init];
  theWorkflow = [[WFWorkflow alloc] init];
  theLoadShowActionWL = [[LSLoadShowActionWL alloc] initWithData:theModel];
  theSelectButtonWL = [[LSSelectButtonWL alloc] initWithData:theModel view:self];
  theNavigationBarWL = [[LSNavigationBarWL alloc] initWithData:theModel view:self];
  theShowCollectionWL = [[LSShowCollectionWL alloc] initWithData:theModel view:self];
  theSubscribeButtonWL = [[LSSubscribeButtonWL alloc] initWithData:theModel view:self];
  theSubscribeActionWL = [[LSSubscribeActionWL alloc] initWithData:theModel view:self];
  //
  [[[[[[theWorkflow
    link:theLoadShowActionWL]
    link:theSelectButtonWL]
    link:theShowCollectionWL]
    link:theNavigationBarWL]
    link:theSubscribeButtonWL]
    link:theSubscribeActionWL
  ];
  __weak LSSelectButtonWL* weakSelectButtonWL = theSelectButtonWL;
  [theSubscribeActionWL setForwardBlockHandler:^()
  {
    [weakSelectButtonWL clicked];
  }];

//  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
  self.edgesForExtendedLayout = UIRectEdgeNone;
     theCollectionView.window.backgroundColor = [UIColor colorWithRed:(245/255.0) green:(245/255.0) blue:(245/255.0) alpha:1.f];


  
  [theWorkflow start];
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
  LSShowAlbumCellModel* cellModel = [theShowCollectionWL itemAtIndex:indexPath];
  cell.detail.text = cellModel.showInfo.title;
  cell.image.image = cellModel.artwork;
 
//    UIGraphicsBeginImageContext(CGSizeMake(320, 20));
//  [theCollectionView.window.viewForBaselineLayout.layer renderInContext:UIGraphicsGetCurrentContext()];
//  UIImage *r1esultingImage = UIGraphicsGetImageFromCurrentImageContext();
//  cell.image.image = r1esultingImage;
//  UIGraphicsEndImageContext();

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
}

- (void) createSubscribeToolbar
{
  UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  theSubscribeButton = [[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStylePlain target:self action:@selector(subscribeButtonClicked:)];
  NSArray *buttons = [NSArray arrayWithObjects:flexibleItem, theSubscribeButton, flexibleItem, nil];
  //
  CGRect optimalRect = self.tabBarController.tabBar.frame;
  optimalRect.size.height -= 5;
  optimalRect.origin.y += 5;
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
//  CGRect rect = theCollectionView.frame;
//  // fix frame due the reason that frame takes height of tab bar and navigation bar
//  rect.size.height -= self.tabBarController.tabBar.frame.size.height;
//  rect.size.height -= self.navigationController.navigationBar.frame.size.height;
//  //
//  theCollectionViewLoadingStub = [[UILoadingView alloc] initWithFrame:rect];
//  [theCollectionViewLoadingStub setText:@"Loading..."];
//  [theCollectionView.viewForBaselineLayout addSubview:theCollectionViewLoadingStub];
//  theCollectionViewLoadingStub.hidden = YES;
  
//    [self.navigationController.view addSubview:theCollectionViewLoadingStub];
//temp= [[CHLoadingWindow alloc] init];
//[temp makeKeyAndVisible];
  
  
  CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
  CGRect winFrame = statusBarFrame;
  winFrame.origin.y = -winFrame.size.height;
  myWindow = [[UIWindow alloc] initWithFrame:winFrame];
  [myWindow setWindowLevel:UIWindowLevelStatusBar+1];
  [myWindow makeKeyAndVisible];
  
  temp = [[UIStatusBarView alloc] initWithFrame:statusBarFrame];
  [temp setText:@"Publishing Tweet..."];
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

//  [UIView beginAnimations:@"foo" context:nil];
//[UIView setAnimationDuration:1.0];
//  [[self navigationController] setNavigationBarHidden:NO animated:YES];

//  CGRect df = self.view.frame;

//  CGRect df1 = self.view.frame;

//  [myWindow setHidden:NO];
//[UIView commitAnimations];


//  self.edgesForExtendedLayout = UIRectEdgeNone;
//            CGRect frame=self.view.frame;
//            frame.origin.y=20;
//            frame.size.height-=20;
//            self.view.frame=frame;
//
//  CGRect df = temp.frame;
//  CGRect df1 = temp.frame;
//  df.origin.y = -20;
////
//  self.view.frame = df;
//  
//  self
//  
//  [UIView animateWithDuration:0.4
//                     animations:^{ self.view.frame = df1;}
//                     completion:nil];

//  temp.hidden = YES;
  
  
  
//  [UIView animateWithDuration:0.4 
//                     animations:^{temp.frame = df;}
//                     completion:nil];
  
//  [UIView beginAnimations:@"slideOn" context:nil];

//firstView.frame = shrunkFirstViewRect; // The rect defining the first view's smaller frame. This should resize the first view

//secondView.frame = secondViewOnScreenFrame; // This should move the second view on the frame.

//[UIView commitAnimations];
}

@end
