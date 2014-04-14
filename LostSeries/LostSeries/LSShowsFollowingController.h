//
//  LSShowsFollowingController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>
// LS
#import "LSControllerCollectionBase.h"
#import <WorkflowLink/WorkflowLink.h>


@protocol LSViewFollowingShowsCollection
- (void) showCollectionReloadData;
- (void) showCollectionUpdateItemAtIndex:(NSIndexPath*)indexPath;
- (NSRange) showCollectionVisibleItemRange;
- (BOOL) showCollectionIsActive;
@end


@protocol LSViewFollowingSwitcherShowDetails <NSObject>
- (void) switchToController:(NSString*)identifier;
@end


//
// LSShowsFollowingController
//

@interface LSShowsFollowingController : LSControllerCollectionBase
  <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIActionSheetDelegate,
    LSViewFollowingShowsCollection,
    LSViewFollowingSwitcherShowDetails
  >

- (WFWorkflow*) workflow;

@end


//
// Notifications
//

extern NSString* LSShowsFollowingControllerDidLoadNotification; // device token has been recieved
