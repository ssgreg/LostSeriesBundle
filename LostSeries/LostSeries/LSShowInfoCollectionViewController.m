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
  LSCachingServer* theCachingServer;
  LSAsyncBackendFacade* theBackendFacade;
  
  NSMutableArray* theItems;
  IBOutlet UICollectionView* theCollectionView;
  LSBatchArtworkGetter* theArtworkGetter;
  NSArray* theArtworkGetterPriorities;
}

- (void) updatePriorities;

@end

@implementation LSShowInfoCollectionViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
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
    cell.image.image = cellModel.artwork;
    [cell setNeedsLayout];
  }
}

@end
