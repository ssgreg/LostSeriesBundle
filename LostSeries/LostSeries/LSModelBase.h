//
//  LSModelBase.h
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Remote/LSAsyncBackendFacade.h"
#import "Jet/JetPartialArray.h"


//
// LSModelShowsLists
//

@interface LSModelShowsLists : NSObject

- (id) initWithShows:(NSArray*)shows;

@property (readonly) JetArrayPartial* shows;
@property (readonly) JetArrayPartial* showsFiltered;

@property (readonly) JetArrayPartial* showsFollowing;
@property (readonly) JetArrayPartial* showsFollowingFiltered;

@property (readonly) JetArrayPartial* showsSelected;
@property (readonly) JetArrayPartial* showsToChangeFollowing;

@end


//
// LSShowAlbumCellModel
//

@interface LSShowAlbumCellModel : NSObject
@property LSShowInfo* showInfo;
@property UIImage* artwork;
@end


//
// Getter protocols
//

@protocol LSDataBaseFacadeAsyncBackend
@property (readonly) LSAsyncBackendFacade* backendFacade;
@end

@protocol LSDataBaseModeSelection
@property BOOL selectionModeActivated;
@end

@protocol LSDataBaseModeFollowing
@property BOOL followingModeFollow;
@end

@protocol LSDataBaseShows
@property (readonly) NSArray* shows;
@property NSArray* showsFiltered;
@end

@protocol LSDataBaseShowsSelected
@property (readonly) JetArrayPartial* showsSelected;
@end

@protocol LSDataBaseShowsFollowing
@property (readonly) JetArrayPartial* showsFollowing;
@property JetArrayPartial* showsFollowingFiltered;
@end

@protocol LSDataBaseShowsRaw
@property NSArray* showsRaw;
@end

@protocol LSDataBaseShowsFavoriteRaw
@property NSArray* showsFavoriteRaw;
@end

@protocol LSDataBaseModelShowsLists
@property LSModelShowsLists* modelShowsLists;
@end

@protocol LSDataBaseModelShowForDatails
@property LSShowAlbumCellModel* showForDetails;
@end


//
// LSModelBase
//

@interface LSModelBase : NSObject
    <
      LSDataBaseShowsRaw
    , LSDataBaseShowsFavoriteRaw
    , LSDataBaseModelShowsLists
    , LSDataBaseModeFollowing
    , LSDataBaseModeSelection
    , LSDataBaseShows
    , LSDataBaseShowsSelected
    , LSDataBaseFacadeAsyncBackend
    , LSDataBaseShowsFollowing
    , LSDataBaseModelShowForDatails
    >

@property NSArray* episodesUnwatchedRaw;

- (id) init;
- (void) modelDidChange;

@end


//
// Notifications
//

extern NSString* LSModelBaseDidChange;
