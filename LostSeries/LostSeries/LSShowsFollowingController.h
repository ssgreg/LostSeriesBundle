//
//  LSShowsFollowingController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>
// LS
#import <WorkflowLink/WorkflowLink.h>


@protocol LSViewFollowingShowsCollection
- (void) showCollectionReloadData;
- (NSRange) showCollectionVisibleItemRange;
- (void) showCollectionUpdateItemAtIndex:(NSIndexPath*)indexPath;
- (BOOL) isActive;
@end


//
// LSShowsFollowingController
//

@interface LSShowsFollowingController : UICollectionViewController
  <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIActionSheetDelegate,
    LSViewFollowingShowsCollection
  >

- (WFWorkflow*) workflow;

@end


//
// Notifications
//

extern NSString* LSShowsFollowingControllerDidLoadNotification; // device token has been recieved
