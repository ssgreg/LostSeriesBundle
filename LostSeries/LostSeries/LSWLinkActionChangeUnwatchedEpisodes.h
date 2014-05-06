//
//  LSWLinkActionChangeUnwatchedEpisodes.h
//  LostSeries
//
//  Created by Grigory Zubankov on 05/05/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "Remote/LSAsyncBackendFacade.h"
#import "LSModelShow.h"
// WF
#import <WorkflowLink/WorkflowLink.h>


//
// LSWLinkActionChangeUnwatchedEpisodes
//

@interface LSWLinkActionChangeUnwatchedEpisodes : WFWorkflowLink
@end


//
// LSViewActionChangeUnwatchedEpisodes
//

@protocol LSViewActionChangeUnwatchedEpisodes <NSObject>
- (void) updateActionIndicatorChangeUnwatchedEpisodes:(BOOL)flag;
@end


//
// LSDataActionChangeUnwatchedEpisodes
//

@protocol LSDataActionChangeUnwatchedEpisodes <NSObject>
// input data
@property (readonly) LSAsyncBackendFacade* backendFacade;
@property (readonly) NSArray* episodesToChange;
@property (readonly) BOOL flagRemove;
// input/output data
@property (readonly) LSShowAlbumCellModel* show;
// methods
- (void) modelDidChange;
@end