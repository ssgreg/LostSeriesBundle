//
//  WorkflowLink.h
//  WorkflowLink
//
//  Created by Grigory Zubankov on 07/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>


//
// WFWorkflowLinkProtocol
//

@protocol WFWorkflowLinkProtocol

- (void) update;
- (void) input;
- (void) block;

@end


//
// WFWorkflowLinkProtocol
//

@interface WFWorkflowLink : NSObject <WFWorkflowLinkProtocol>

- (id) initWithData:(id)data view:(id)view;
- (id) initWithData:(id)data;
- (id) initWithView:(id)view;

- (id) workflowData;
- (id) workflowView;

- (void) setOutputHandler:(void (^)())handler;
- (void) setForwardBlockHandler:(void (^)())handler;
- (void) output;
- (void) forwardBlock;

- (void) block;
- (void) update;
- (void) input;

@end


//
// WFWorkflow
//

@interface WFWorkflow : NSObject

- (id) init;
- (WFWorkflow*) link:(WFWorkflowLink<WFWorkflowLinkProtocol>*) workflowLink;
- (void) start;

@end


#define SYNTHESIZE_WL_ACCESSORS(dataType, viewType) \
- (id<dataType>) data { return self.workflowData; } \
- (id<viewType>) view { return self.workflowView; }

#define SYNTHESIZE_WL_DATA_ACCESSOR(dataType) \
- (id<dataType>) data { return self.workflowData; }

#define SYNTHESIZE_WL_VIEW_ACCESSOR(viewType) \
- (id<viewType>) view { return self.workflowView; }
