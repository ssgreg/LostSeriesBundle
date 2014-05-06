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
#import "LSWLinkActionChangeFollowing.h"
#import "LSWLinkActionChangeUnwatchedEpisodes.h"
#import "LSModelBase.h"


@interface LSDataControllerShowDetails : NSObject <LSDataActionChangeFollowing, LSDataActionChangeUnwatchedEpisodes>

- initWithModel:(LSModelBase*)model show:(LSShowAlbumCellModel*)show;

// input data
@property (readonly) LSAsyncBackendFacade* backendFacade;
@property (readonly) LSShowAlbumCellModel* show;
@property (readonly) NSArray* shows;
// local data
@property NSArray* episodesToChange;
@property NSArray* episodesSorted;
@property BOOL flagUnfollow;
@property BOOL flagRemove;
// methods
- (void) modelDidChange;
- (BOOL) isShowFollowedByUser;
- (NSInteger) indexOfShow;
- (BOOL) isEpisodeUnwatchedWithNumber:(NSInteger)number;

@end



@protocol LSViewActionGetFullSizeArtwork <NSObject>
- (void) setImageArtwork:(UIImage*)image;
@end

@protocol LSViewShowDescription <NSObject>
- (void) setShowInfo:(LSShowInfo*)info;
@end

@protocol LSViewEventChangeFollowing <NSObject>
- (void) setIsFollowing:(BOOL)isFollowing;
@end

@protocol LSViewCollectionEpisodes <NSObject>
- (void) reloadCollectionEpisodes;
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
    LSViewCollectionEpisodes,
    LSViewEventChangeFollowing,
    LSViewActionChangeFollowing,
    LSViewActionChangeUnwatchedEpisodes
  >

@end


extern NSString* LSControllerShowDetailsShortID;
