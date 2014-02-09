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


@protocol LSSelectButtonView
- (void) selectButtonTurnIntoSelect;
- (void) selectButtonTurnIntoCancel;
- (void) selectButtonDisable:(BOOL)flag;
@end


@protocol LSNavigationView
- (void) navigationSetTitle:(NSString*)title;
@end


@protocol LSShowCollectionView
- (void) showCollectionClearSelection;
- (void) showCollectionAllowMultipleSelection:(BOOL)flag;
- (void) showCollectionUpdateItemAtIndex:(NSIndexPath*)indexPath;
- (NSArray*) showCollectionVisibleItemIndexs;
@end


@protocol LSShowSubscribeButtonView
- (void) enableSubscribeButton:(BOOL)flag;
- (void) showSubscribeButton:(BOOL)flag;
@end


@protocol LSSubscribeActionView
- (void) showActionIndicator:(BOOL)flag;
@end


@interface LSShowInfoCollectionViewController : UICollectionViewController
  <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIActionSheetDelegate,
    LSSelectButtonView,
    LSNavigationView,
    LSShowCollectionView,
    LSShowSubscribeButtonView,
    LSSubscribeActionView
  >

- (IBAction) selectButtonClicked:(id)sender;
- (IBAction) subscribeButtonClicked:(id)sender;

@end
