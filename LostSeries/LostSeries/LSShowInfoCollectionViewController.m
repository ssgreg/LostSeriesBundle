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



@interface LSShowInfoCollectionViewController ()
{
  NSMutableDictionary* theSelectedShows;
  BOOL theSelectionModeFlag;

  LSCachingServer* theCachingServer;
  LSAsyncBackendFacade* theBackendFacade;
  
  NSMutableArray* theItems;
  IBOutlet UICollectionView* theCollectionView;
  IBOutlet UIBarButtonItem* theSelectButton;
  IBOutlet UINavigationItem* theNavigationItem;
  
  UIToolbar* theSubscribeToolbar;
  UIBarButtonItem* theSubscribeButton;

  LSBatchArtworkGetter* theArtworkGetter;
  NSArray* theArtworkGetterPriorities;
}

- (void) updatePriorities;
- (void) updateCell:(LSShowAlbumCell*)cell forIndexPath:(NSIndexPath*)indexPath;
- (void) createSubscribeToolbar;
- (NSString*) formatSelectedShowInfo;

@end

@implementation LSShowInfoCollectionViewController

- (IBAction) selectButtonClicked:(id)sender;
{
  theSelectionModeFlag = !theSelectionModeFlag;
  theCollectionView.allowsMultipleSelection = theSelectionModeFlag;
  if (!theSelectionModeFlag)
  {
    theSelectButton.title = @"Select";
    theSelectButton.style = UIBarButtonItemStylePlain;
    theNavigationItem.title = @"Lost Series";
    //
    theSubscribeToolbar.hidden = YES;
    self.tabBarController.tabBar.hidden = NO;
    //
    [theSelectedShows removeAllObjects];
    [theCollectionView reloadData];
  }
  else
  {
    theSelectButton.title = @"Cancel";
    theSelectButton.style = UIBarButtonItemStyleDone;
    theNavigationItem.title = [self formatSelectedShowInfo];
    //
    theSubscribeToolbar.hidden = NO;
    theSubscribeButton.enabled = NO;
    self.tabBarController.tabBar.hidden = YES;
  }
}

- (IBAction) subscribeButtonClicked:(id)sender
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Subscribe", nil];
  [actionSheet showInView:self.view];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  [self createSubscribeToolbar];
  theSelectedShows = [NSMutableDictionary dictionary];
  theSelectionModeFlag = NO;
  //
  theCachingServer = [[LSCachingServer alloc] init];
  theBackendFacade = [LSAsyncBackendFacade backendFacade];
  //
  [theBackendFacade getShowInfoArray:^(NSArray* shows)
  {
    NSMutableArray* newShows = [NSMutableArray array];
    //    for (int i = 0; i < 40; ++i)
    //    {
    //      [newShows addObject:shows[0]];
    //    }
    for (id show in shows)
    {
      [newShows addObject:show];
      [newShows addObject:show];
    }

    theItems = [NSMutableArray array];
    for (id show in newShows)
    {
      LSShowAlbumCellModel* cellModel = [LSShowAlbumCellModel showAlbumCellModel];
      cellModel.showInfo = show;
      [theItems addObject: cellModel];
    }

    [theCollectionView reloadData];
    theArtworkGetter = [LSBatchArtworkGetter artworkGetterWithDelegate:self];
  }];
}

- (void) updatePriorities
{
  NSMutableArray* indexes = [NSMutableArray array];
  NSArray* cells = [theCollectionView visibleCells];
  for (LSShowAlbumCell* cell in cells)
  {
    NSNumber* index = [NSNumber numberWithInteger:[theCollectionView indexPathForCell:cell].row];
    [indexes addObject:index];
  }
  theArtworkGetterPriorities = [indexes sortedArrayUsingComparator:^(id obj1, id obj2)
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
  LSShowAlbumCellModel* cellModel = [theItems objectAtIndex:indexPath.row];
  cell.detail.text = cellModel.showInfo.title;
  cell.image.image = cellModel.artwork;
  cell.image.alpha = 1;
  cell.overlay.hidden = YES;
  //
  if ([theSelectedShows objectForKey:indexPath])
  {
    cell.image.alpha = 0.66;
    cell.overlay.hidden = NO;
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
  theSubscribeToolbar = [[UIToolbar alloc] initWithFrame:optimalRect];
  [theSubscribeToolbar setItems:buttons animated:NO];
  theSubscribeToolbar.hidden = YES;
  [self.view addSubview:theSubscribeToolbar];
}

- (NSString*) formatSelectedShowInfo
{
  if (theSelectedShows.count == 0)
  {
    return @"Select Items";
  }
  return [NSString stringWithFormat:@"%ld %@ Selected", theSelectedShows.count, (theSelectedShows.count == 1 ? @"Show" : @"Shows")];
}

#pragma mark - UICollectionViewDataSource implementationr


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [theItems count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  //
  [self updatePriorities];
  //
  LSShowAlbumCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"theCell" forIndexPath:indexPath];
  [self updateCell:cell forIndexPath:indexPath];
  return cell;
}


#pragma mark - UICollectionViewDelegate implementation


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  //  NSLog(@"Decelerating");
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  //  NSLog(@"Dragging, %ld", decelerate);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (theCollectionView.allowsMultipleSelection)
  {
    theSelectedShows[indexPath] = @YES;
    LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
    theSubscribeButton.enabled = theSelectedShows.count > 0;
    theNavigationItem.title = [self formatSelectedShowInfo];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath*)indexPath
{
  if (theCollectionView.allowsMultipleSelection)
  {
    [theSelectedShows removeObjectForKey:indexPath];
    LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
    theSubscribeButton.enabled = theSelectedShows.count > 0;
    theNavigationItem.title = [NSString stringWithFormat:@"%ld Shows Selected", theSelectedShows.count];
    theNavigationItem.title = [self formatSelectedShowInfo];
  }
}


#pragma mark - UIActionSheetDelegate implementation


- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 0)
  {
    [self selectButtonClicked:self];
  }
}


#pragma mark - LSBatchArtworkGetterDelegate implementation


- (NSInteger) getNumberOfItems
{
  return [theItems count];
}

- (NSArray*) getPriorityWindow
{
  return theArtworkGetterPriorities;
}

- (void) getArtworkAsyncForIndex:(NSInteger)index completionHandler:(void (^)(NSData*))handler
{
  LSShowAlbumCellModel* cellModel = [theItems objectAtIndex:index];
  [theBackendFacade getArtworkByShowInfo:cellModel.showInfo replyHandler:handler];
}

- (void) didGetArtwork:(NSData*)data forIndex:(NSInteger)index
{
  // update cache
  LSShowAlbumCellModel* cellModel = [theItems objectAtIndex:index];
  cellModel.artwork = [UIImage imageWithData:data];
  // update view
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath];
  if (cell)
  {
    [self updateCell:cell forIndexPath:indexPath];
    [cell setNeedsLayout];
  }
}

@end
