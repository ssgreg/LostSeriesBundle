//
//  LSWLinkActionChangeFollowing.h
//  LostSeries
//
//  Created by Grigory Zubankov on 18/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSModelBase.h"
// WF
#import <WorkflowLink/WorkflowLink.h>


//
// LSWLinkActionChangeFollowing
//

@interface LSWLinkActionChangeFollowing : WFWorkflowLink
@end


//
// LSViewActionChangeFollowing
//

@protocol LSViewActionChangeFollowing
- (void) updateActionIndicatorChangeFollowing:(BOOL)flag;
@end
