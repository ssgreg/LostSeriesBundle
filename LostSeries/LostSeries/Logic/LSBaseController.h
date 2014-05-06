//
//  LSBaseController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 23/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// WF
#import <WorkflowLink/WorkflowLink.h>


//
// LSBaseController
//

@protocol LSBaseController <NSObject>

@property NSString* idController;
@property (readonly) NSString* idControllerShort;
- (WFWorkflow*) workflow:(id)model;

@end



NSString* MakeIdController(NSString* parent, NSString* child);
