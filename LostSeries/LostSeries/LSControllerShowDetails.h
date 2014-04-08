//
//  LSControllerShowDetails.h
//  LostSeries
//
//  Created by Grigory Zubankov on 25/03/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>
// WL
#import <WorkflowLink/WorkflowLink.h>
// LS
#import "LSAsyncBackendFacade.h"


@protocol LSViewActionGetFullSizeArtwork <NSObject>
- (void) setImageArtwork:(UIImage*)image;
@end

@protocol LSViewShowDescription <NSObject>
- (void) setShowInfo:(LSShowInfo*)info;
@end


//
// LSControllerShowDetails
//

@interface LSControllerShowDetails : UIViewController
  <
    UITableViewDataSource,
    UITableViewDelegate,
    LSViewActionGetFullSizeArtwork,
    LSViewShowDescription
  >
//@property NSString* idController;
- (void) setIdController:(NSString*)idController;

@property (readonly) WFWorkflow* workflow;
@end
