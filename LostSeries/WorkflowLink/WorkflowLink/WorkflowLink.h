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

@property BOOL isBlocked;
@property WFWorkflowLink* nextLink;

- (id) initWithData:(id)data view:(id)view;
- (id) initWithData:(id)data;
- (id) initWithView:(id)view;

- (id) workflowData;
- (id) workflowView;

- (void) output;
- (void) forwardBlock;

- (void) block;
- (void) update;
- (void) input;

@end


//
// WFWorkflowBatch
//

@interface WFWorkflowBatch : WFWorkflowLink

- (id) initWithFirstWLink:(WFWorkflowLink*)wLinkFirst lastWLink:(WFWorkflowLink*)wLinkLast;

@end


//
// WFForwardWorkflowLink
//

@interface WFForwardWorkflowLink : WFWorkflowLink

- (id) initWithOutputHandler:(void (^)())outputHandler forwardBlockHandler:(void (^)())forwardBlockHandler;

- (void) input;
- (void) block;

@end


//
// WFWorkflowBatchWithOutputCondition
//

@interface WFWorkflowBatchWithOutputCondition : WFWorkflowLink

- (id) initWithArray:(NSArray*)wls outputCodition:(BOOL(^)(NSArray*wls, WFWorkflowLink* wl))condition;

@end

//
// WFWorkflowSplitterWithOutputUsingAnd
//

@interface WFWorkflowSplitterWithOutputUsingAnd : WFWorkflowBatchWithOutputCondition

- (id) initWithArray:(NSArray*)wls;

@end


//
// WFWorkflowSplitterWithOutputUsingOr
//

@interface WFWorkflowSplitterWithOutputUsingOr : WFWorkflowBatchWithOutputCondition

- (id) initWithArray:(NSArray*)wls;

@end


typedef WFWorkflowLink WFWorkflow;

WFWorkflow* WFLinkWorkflow(WFWorkflowLink* wl, ...);
WFWorkflow* WFSplitWorkflowWithOutputUsingAnd(WFWorkflowLink* wl, ...);
WFWorkflow* WFSplitWorkflowWithOutputUsingOr(WFWorkflowLink* wl, ...);
WFWorkflow* WFLinkToSelfForward(WFWorkflowLink* wlSelf);


#define SYNTHESIZE_WL_ACCESSORS(dataType, viewType) \
- (id<dataType>) data { return self.workflowData; } \
- (id<viewType>) view { return self.workflowView; }

#define SYNTHESIZE_WL_DATA_ACCESSOR(dataType) \
- (id<dataType>) data { return self.workflowData; }

#define SYNTHESIZE_WL_VIEW_ACCESSOR(viewType) \
- (id<viewType>) view { return self.workflowView; }
