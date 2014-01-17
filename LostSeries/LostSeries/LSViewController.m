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
  LSProtocol* theProtocol;
  IBOutlet UICollectionView* theCollectionView;
}
@end

@implementation LSViewController

//- (void)image:(UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
//  NSLog(@"SAVE IMAGE COMPLETE");
//  if(error != nil) {
//    NSLog(@"ERROR SAVING:%@",[error localizedDescription]);
//  }
//}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  theConnection = [LSConnection connection];
  theProtocol = [LSProtocol protocolWithChannel:[theConnection createPriorityChannel]];
  //
  [theProtocol getShowInfoArray: ^(NSArray* shows)
  {
    dispatch_async(dispatch_get_main_queue(),
    ^{
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
    });
  }];
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
  NSLog(@"settttt=%ld", indexPath.row);
  
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
