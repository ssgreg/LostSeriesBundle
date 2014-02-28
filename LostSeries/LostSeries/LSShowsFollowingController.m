//
//  LSShowsFollowingController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSShowsFollowingController.h"
#import "LSModelBase.h"
#import "Logic/LSApplication.h"



//
// LSCellFollowingShows
//

@interface LSCellFollowingShows : UICollectionViewCell
@property IBOutlet UIImageView* overlay;
@property IBOutlet UIImageView* image;
@property IBOutlet UIImageView* subscriptionOverlay;
@property IBOutlet UILabel* detail;
@end

@implementation LSCellFollowingShows
@end


//
// LSWLinkFollowingShowsCollection
//

@protocol LSDataFollowingShowsCollection <LSDataBaseShows, LSDataBaseShowsFollowing, LSDataBaseFacadeAsyncBackend>
@end

@interface LSWLinkFollowingShowsCollection : WFWorkflowLink <LSClientServiceArtworkGetters>

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) itemsCount;

@end

@implementation LSWLinkFollowingShowsCollection
{
  NSRange theRangeVisibleItems;
  NSInteger theIndexNext;
}

SYNTHESIZE_WL_ACCESSORS(LSDataFollowingShowsCollection, LSViewFollowingShowsCollection);

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath
{
  return self.data.showsFollowing[indexPath.row];
}

- (NSUInteger) itemsCount
{
  return self.data.showsFollowing.count;
}

- (void) update
{
  [self updateView];
  //
  theRangeVisibleItems = NSMakeRange(INT_MAX, INT_MAX);
  theIndexNext = INT_MAX;
  // artworks
  [[LSApplication singleInstance].serviceArtworkGetter addClient:self];
}

- (void) input
{
  [self updateIndexes];
  [self updateView];
  [self output];
}

- (void) updateView
{
  [self.view showCollectionReloadData];
}

- (void) updateIndexes
{
  
}

#pragma mark - LSBatchArtworkGetterDelegate implementation

- (BOOL) isInBackgroundForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  return [self.view isActive] == NO;
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
    ? [self.data.showsFollowing indexTargetToSource:theIndexNext++]
    : INT_MAX;
}

- (void) serviceArtworkGetter:(LSServiceArtworkGetter*)service didGetArtworkAtIndex:(NSInteger)index
{
  NSInteger indexTarget = [self.data.showsFollowing indexSourceToTarget:index];
  if (indexTarget != INT_MAX)
  {
    [self.view showCollectionUpdateItemAtIndex:[NSIndexPath indexPathForRow:indexTarget inSection:0]];
  }
}

@end


//
// LSShowsFollowingController
//

@implementation LSShowsFollowingController
{
  IBOutlet UICollectionView* theCollectionView;
  IBOutlet UINavigationItem* theNavigationItem;
  // workflow
  WFWorkflow* theWorkflow;
  LSWLinkFollowingShowsCollection* theWLinkCollection;
}

- (WFWorkflow*) workflow
{
  return theWorkflow;
}

- (void) updateCell:(LSCellFollowingShows*)cell forIndexPath:(NSIndexPath*)indexPath
{
  LSShowAlbumCellModel* model = [theWLinkCollection itemAtIndex:indexPath];
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
  cell.image.alpha = 1;
  cell.overlay.hidden = YES;
  cell.subscriptionOverlay.hidden = YES;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  theWLinkCollection = [[LSWLinkFollowingShowsCollection alloc] initWithData:[LSApplication singleInstance].modelBase view:self];

  theWorkflow = WFLinkWorkflow(
      theWLinkCollection
    , nil);
  
  [[NSNotificationCenter defaultCenter] postNotificationName:LSShowsFollowingControllerDidLoadNotification object:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void) showCollectionReloadData
{
  [theCollectionView reloadData];
}

- (BOOL) isActive
{
  return self.tabBarController.selectedIndex == 1;
}

- (NSRange) showCollectionVisibleItemRange
{
  NSArray* indexPaths = [theCollectionView indexPathsForVisibleItems];
  if (indexPaths.count)
  {
    NSInteger xmax = INT_MIN, xmin = INT_MAX;
    for (NSIndexPath* indexPath in indexPaths)
    {
      NSInteger x = indexPath.row;
      if (x < xmin) xmin = x;
      if (x > xmax) xmax = x;
    }
    return NSMakeRange(xmin, xmax - xmin + 1);
  }
  else
  {
    return NSMakeRange(0, 15);
  }
}

- (void) showCollectionUpdateItemAtIndex:(NSIndexPath*)indexPath
{
  LSCellFollowingShows* cell = (LSCellFollowingShows*)[theCollectionView cellForItemAtIndexPath:indexPath];
  if (cell)
  {
    [self updateCell:cell forIndexPath:indexPath];
    [cell setNeedsLayout];
  }
}

#pragma mark - UICollectionViewDataSource implementation

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  NSUInteger itemCount = [theWLinkCollection itemsCount];
//  theCollectionViewLoadingStub.hidden = itemCount > 0;
  return itemCount;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  LSCellFollowingShows* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"theCellFollowingShows" forIndexPath:indexPath];
  [self updateCell:cell forIndexPath:indexPath];
  return cell;
}

@end


//
// Notifications
//

NSString* LSShowsFollowingControllerDidLoadNotification = @"LSShowsFollowingControllerDidLoadNotification";
