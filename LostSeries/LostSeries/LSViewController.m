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
}

- (void) updateItems;

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
  [thePriorityProtocol getShowInfoArray: ^(NSArray* shows)
  {
    theItems = [NSMutableArray array];
    for (int i = 1; i < 40; ++i)
    {
      for (id show in shows)
      {
        LSShowAlbumCellModel* cellModel = [LSShowAlbumCellModel showAlbumCellModel];
        cellModel.showInfo = show;
        [theItems addObject: cellModel];
      }
    }
    [theCollectionView reloadData];
    [self updateItems];
  }];
}

- (void) updateItems
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
  ^{
    NSInteger row = 0;
    for (LSShowAlbumCellModel* item in theItems)
    {
      [theBackgroundProtocol getArtwork:item.showInfo completionHandler: ^(NSData* artworkData)
      {
        item.artwork = [UIImage imageWithData:artworkData];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        LSShowAlbumCell* blockCell = (LSShowAlbumCell*)[theCollectionView cellForItemAtIndexPath: indexPath];
        blockCell.image.image = item.artwork;
        [blockCell setNeedsLayout];
      }];
      ++row;
    }
  });
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [theItems count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  LSShowAlbumCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"theCell" forIndexPath:indexPath];
  //
  LSShowAlbumCellModel* cellModel = [theItems objectAtIndex: indexPath.row];
  cell.detail.text = cellModel.showInfo.title;
  cell.image.image = cellModel.artwork;
  
//
  if (!cellModel.artwork)
  {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
//                   ^{
//                     NSData* artworkData = [theServerRoutine askArtworkByOriginalTitle:cellModel.showInfo.originalTitle snapshot:cellModel.showInfo.snapshot];
//                     cellModel.artwork = [UIImage imageWithData:artworkData];
//                     NSLog(@"req=%ld", indexPath.row);
//                     dispatch_async(dispatch_get_main_queue(),
//                                    ^{
//                                      LSShowAlbumCell* blockCell = (LSShowAlbumCell*)[collectionView cellForItemAtIndexPath: indexPath];
//                                      blockCell.image.image = cellModel.artwork;
//                                      [blockCell setNeedsLayout];
//                                    });
//                   });
  }
  return cell;
}


@end
