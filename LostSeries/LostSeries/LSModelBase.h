//
//  LSModelBase.h
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Remote/LSAsyncBackendFacade.h"


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

@protocol LSShowAsyncBackendFacadeData
@property (readonly) LSAsyncBackendFacade* backendFacade;
@end

@protocol LSShowsSelectionModeData
@property BOOL selectionModeActivated;
@end

@protocol LSShowsShowsData
@property NSArray* shows;
@end

@protocol LSShowsSelectedShowsData
@property NSDictionary* selectedShows;
@end

@protocol LSShowsFavoriteShowsData
@property NSDictionary* favoriteShows;
@end

@protocol LSDataBaseShowsRaw
@property NSArray* showsRaw;
@end

@protocol LSDataBaseShowsFavoriteRaw
@property NSArray* showsFavoriteRaw;
@end


//
// LSModelBase
//

@interface LSModelBase : NSObject
    < LSDataBaseShowsRaw
    , LSDataBaseShowsFavoriteRaw
    , LSShowsSelectionModeData
    , LSShowsFavoriteShowsData
    , LSShowsShowsData
    , LSShowsSelectedShowsData
    , LSShowAsyncBackendFacadeData>

- (id) init;

@end
