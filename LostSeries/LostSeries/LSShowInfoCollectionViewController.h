//
//  LSShowInfoCollectionViewController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 30/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>
// LS
#import "LSControllerCollectionBase.h"
#import <WorkflowLink/WorkflowLink.h>


@protocol LSSelectButtonView
- (void) selectButtonTurnIntoSelect;
- (void) selectButtonTurnIntoCancel;
- (void) selectButtonDisable:(BOOL)flag;
@end


@protocol LSNavigationView
- (void) navigationSetTitle:(NSString*)title;
@end


@protocol LSViewShowsCollection
- (void) showCollectionReloadData;
- (void) showCollectionUpdateItemAtIndex:(NSIndexPath*)indexPath;
- (NSRange) showCollectionVisibleItemRange;
- (BOOL) showCollectionIsActive;
@end


@protocol LSViewShowsSelection
- (void) showCollectionClearSelection;
- (void) showCollectionAllowMultipleSelection:(BOOL)flag;
@end


@protocol LSShowSubscribeButtonView
- (void) enableSubscribeButton:(BOOL)flag;
- (void) showSubscribeButton:(BOOL)flag;
@end


@protocol LSSubscribeActionView
- (void) showActionIndicator:(BOOL)flag;
@end


@interface LSShowInfoCollectionViewController : LSControllerCollectionBase
  <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIActionSheetDelegate,
    LSSelectButtonView,
    LSNavigationView,
    LSViewShowsCollection,
    LSViewShowsSelection,
    LSShowSubscribeButtonView,
    LSSubscribeActionView
  >

- (IBAction) selectButtonClicked:(id)sender;
- (IBAction) subscribeButtonClicked:(id)sender;

- (WFWorkflow*) workflow;

@end


//
// Notifications
//

extern NSString* LSShowsControllerDidLoadNotification; // device token has been recieved
