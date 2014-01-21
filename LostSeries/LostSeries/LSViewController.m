//
//  LSViewController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 09/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSViewController.h"
#import "Remote/LSProtocol.h"
#import "Remote/LSChannel.h"
#import "Remote/LSConnection.h"
#import "Remote/LSBatchArtworkGetter.h"


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
// LSViewController
//

@interface LSViewController ()
{
  NSMutableArray* theItems;
  LSConnection* theConnection;
  LSProtocol* thePriorityProtocol;
  LSProtocol* theBackgroundProtocol;
  IBOutlet UICollectionView* theCollectionView;
  LSBatchArtworkGetter* theArtworkGetter;
  NSArray* theArtworkGetterPriorities;
}

- (void) updatePriorities;

@end

@implementation LSViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  theConnection = [LSConnection connection];
  thePriorityProtocol = [LSProtocol protocolWithChannel:[theConnection createPriorityChannel]];
  theBackgroundProtocol = [LSProtocol protocolWithChannel:[theConnection createBackgroundChannel]];
  //
  [thePriorityProtocol getShowInfoArray:^(NSArray* shows)
  {
    NSMutableArray* newShows = [NSMutableArray array];
    for (int i = 0; i < 40; ++i)
    {
      [newShows addObject:shows[0]];
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


#pragma mark - UICollectionViewDataSource implementation


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
  LSShowAlbumCellModel* cellModel = [theItems objectAtIndex:indexPath.row];
  cell.detail.text = cellModel.showInfo.title;
  cell.image.image = cellModel.artwork;
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
  [thePriorityProtocol getArtwork:cellModel.showInfo completionHandler:handler];
}

- (void) didGetArtwork:(NSData*)data forIndex:(NSInteger)index
{
  // update cache
  LSShowAlbumCellModel* cellModel = [theItems objectAtIndex:index];
  cellModel.artwork = [UIImage imageWithData:data];
  // update view
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  if (LSShowAlbumCell* cell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath:indexPath])
  {
    cell.image.image = cellModel.artwork;
    [cell setNeedsLayout];
  }
}


@end
