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

@protocol LSDataFollowingShowsCollection <LSShowsShowsData, LSShowsFavoriteShowsData, LSShowAsyncBackendFacadeData>
@end

@interface LSWLinkFollowingShowsCollection : WFWorkflowLink <LSClientServiceArtworkGetters>

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) itemsCount;

@end

@implementation LSWLinkFollowingShowsCollection
{
  
}

SYNTHESIZE_WL_ACCESSORS(LSDataFollowingShowsCollection, LSViewFollowingShowsCollection);

- (LSShowAlbumCellModel*) itemAtIndex:(NSIndexPath*)indexPath
{
  return self.data.favoriteShows.allValues[indexPath.row];
}

- (NSUInteger) itemsCount
{
  return self.data.favoriteShows.count;
}

- (void) update
{
  [self updateView];
  // artworks
  [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(onLSFacadeArtworkGetterArtworkDidGetNotification:)
    name:LSServiceArtworkGetterArtworkDidGetNotification
    object:nil];
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

- (void) onLSFacadeArtworkGetterArtworkDidGetNotification:(NSNotification *)notification
{
  NSInteger indexSequential = ((NSNumber*)notification.object).integerValue;
  LSShowAlbumCellModel* model = self.data.favoriteShows[[NSIndexPath indexPathForRow:indexSequential inSection:0]];
  if (model)
  {
    NSInteger index = [self.data.favoriteShows.allValues indexOfObject:model];
    [self.view showCollectionUpdateItemAtIndex:[NSIndexPath indexPathForRow:index inSection:0]];
  }
}

#pragma mark - LSBatchArtworkGetterDelegate implementation

- (BOOL) isInBackgroundForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  return [self.view isActive] == NO;
}

- (NSRange) indexQueueForServiceArtworkGetter:(LSServiceArtworkGetter*)service
{
  
  return [self.view showCollectionVisibleItemRange];
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
  return theCollectionView.hidden == NO;
}

- (NSRange) showCollectionVisibleItemRange
{
  NSArray* indexPaths = [theCollectionView indexPathsForVisibleItems];
  NSInteger xmax = INT_MIN, xmin = INT_MAX;
  for (NSIndexPath* indexPath in indexPaths)
  {
    NSInteger x = indexPath.row;
    if (x < xmin) xmin = x;
    if (x > xmax) xmax = x;
  }
  return NSMakeRange(xmin, xmax - xmin + 1);
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
