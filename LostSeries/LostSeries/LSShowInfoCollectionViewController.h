//
//  LSShowInfoCollectionViewController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 30/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>
// LS
#import "Remote/LSBatchArtworkGetter.h"


@interface LSShowInfoCollectionViewController : UICollectionViewController
  <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIActionSheetDelegate,
    LSBatchArtworkGetterDelegate
  >

- (IBAction) selectButtonClicked:(id)sender;
- (IBAction) subscribeButtonClicked:(id)sender;

@end
