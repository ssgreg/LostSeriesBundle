//
//  LSShowsFollowingController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>
// LS
#import "Logic/LSBaseController.h"
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
    LSBaseController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIActionSheetDelegate,
    LSViewFollowingShowsCollection,
    LSViewFollowingSwitcherShowDetails
  >

@property (readonly) WFWorkflow* workflow;

@end


extern NSString* LSShowsFollowingControllerShortID;
