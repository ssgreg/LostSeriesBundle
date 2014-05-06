//
//  LSWLinkActionChangeFollowing.h
//  LostSeries
//
//  Created by Grigory Zubankov on 18/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "Remote/LSAsyncBackendFacade.h"
// WF
#import <WorkflowLink/WorkflowLink.h>
// Jet
#import "Jet/JetPartialArray.h"


//
// LSWLinkActionChangeFollowing
//

@interface LSWLinkActionChangeFollowing : WFWorkflowLink
@end


//
// LSViewActionChangeFollowing
//

@protocol LSViewActionChangeFollowing <NSObject>
- (void) updateActionIndicatorChangeFollowing:(BOOL)flag;
@end


//
// LSDataActionChangeFollowing
//

@protocol LSDataActionChangeFollowing <NSObject>
// input data
@property (readonly) LSAsyncBackendFacade* backendFacade;
@property (readonly) JetArrayPartial* showsToChange;
@property (readonly) BOOL flagUnfollow;
// input/output data
@property (readonly) JetArrayPartial* showsFollowing;
// methods
- (void) modelDidChange;
@end