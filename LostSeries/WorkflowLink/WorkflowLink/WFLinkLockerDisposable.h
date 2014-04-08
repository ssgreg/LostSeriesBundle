//
//  WFLinkLockerDisposable.h
//  WorkflowLink
//
//  Created by Grigory Zubankov on 06/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// WF
#import <WorkflowLink/WorkflowLink.h>


//
// WFLinkLockerDisposable
//

@interface WFLinkLockerDisposable : WFWorkflowLink
- (void) use;
@end
