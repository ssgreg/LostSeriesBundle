//
//  LSControllerShowDetails.h
//  LostSeries
//
//  Created by Grigory Zubankov on 25/03/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>
// LS
#import "Logic/LSBaseController.h"
#import "LSAsyncBackendFacade.h"
#import "LSWLinkActionChangeFollowing.h"


@protocol LSViewActionGetFullSizeArtwork <NSObject>
- (void) setImageArtwork:(UIImage*)image;
@end

@protocol LSViewShowDescription <NSObject>
- (void) setShowInfo:(LSShowInfo*)info;
@end

@protocol LSViewButtonChangeFollowing <NSObject>
- (void) setTextButtonChangeFollowing:(NSString*)text;
@end

//
// LSControllerShowDetails
//

@interface LSControllerShowDetails : UIViewController
  <
    LSBaseController,
    UITableViewDataSource,
    UITableViewDelegate,
    LSViewActionGetFullSizeArtwork,
    LSViewShowDescription,
    LSViewButtonChangeFollowing,
    LSViewActionChangeFollowing
  >

@end


extern NSString* LSControllerShowDetailsShortID;
