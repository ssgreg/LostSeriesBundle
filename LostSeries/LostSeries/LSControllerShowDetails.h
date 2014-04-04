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


@protocol LSViewActionGetFullSizeArtwork <NSObject>
@end


//
// LSControllerShowDetails
//

@interface LSControllerShowDetails : UIViewController <LSViewActionGetFullSizeArtwork>
@property NSString* idController;
@property (readonly) WFWorkflow* workflow;
@end
