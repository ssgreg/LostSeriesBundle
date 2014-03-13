//
//  LSModelBase.h
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Remote/LSAsyncBackendFacade.h"


@class LSArrayPartial;


//
// LSArrayPartial
//

@interface LSArrayPartial : NSObject <NSFastEnumeration>

+ (LSArrayPartial*) arrayPartialWithArraySource:(NSArray*)arraySource ;
- (id) initWithArraySource:(NSArray*)arraySource;

- (NSInteger) indexSourceToTarget:(NSInteger)indexSource;
- (NSInteger) indexTargetToSource:(NSInteger)indexTarget;

- (BOOL) hasIndexSource:(NSInteger)indexSource;

- (void) addObjectByIndexSource:(NSInteger)indexSource;
- (void) mergeObjectsFromArrayPartial:(LSArrayPartial*)array;
- (void) subtractObjectsFromArrayPartial:(LSArrayPartial*)array;

- (void) removeObjectByIndexSource:(NSInteger)indexSource;
- (void) removeObjectByIndexTarget:(NSInteger)indexTarget;

- (NSInteger) count;
- (void) removeAllObjectes;

// operator []
- (id) objectAtIndexedSubscript:(NSUInteger)index;
- (void) setObject:(id)obj atIndexedSubscript:(NSUInteger)index;

@end


//
// LSModelShowsLists
//

@interface LSModelShowsLists : NSObject

- (id) initWithShows:(NSArray*)shows;

@property (readonly) NSArray* shows;
@property (readonly) LSArrayPartial* showsFollowing;
@property (readonly) LSArrayPartial* showsSelected;

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
@end

@protocol LSDataBaseShowsSelected
@property (readonly) LSArrayPartial* showsSelected;
@end

@protocol LSDataBaseShowsFollowing
@property (readonly) LSArrayPartial* showsFollowing;
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

//
// LSModelBase
//

@interface LSModelBase : NSObject
    < LSDataBaseShowsRaw
    , LSDataBaseShowsFavoriteRaw
    , LSDataBaseModelShowsLists
    , LSDataBaseModeFollowing
    , LSDataBaseModeSelection
    , LSDataBaseShows
    , LSDataBaseShowsSelected
    , LSDataBaseFacadeAsyncBackend
    , LSDataBaseShowsFollowing>

- (id) init;

@end
