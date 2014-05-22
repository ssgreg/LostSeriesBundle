//
//  LSProtocol.h
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
#import "Logic/LSCDID.h"


// forwards
@class LSShowInfo;
@class LSSubscriptionInfo;
@class LSSnapshotInfo;


//
// LSAsyncBackendFacade
//

@interface LSAsyncBackendFacade : NSObject

#pragma mark - Factory Methods
+ (LSAsyncBackendFacade*) backendFacade;

#pragma mark - Init Methods
- (id) init;

#pragma mark - Interface
- (void) getShowInfoArray:(void (^)(NSArray*))handler;
- (void) getArtworkByShowInfo:(LSShowInfo*)showInfo thumbnail:(BOOL)thumbnail replyHandler:(void (^)(NSData*))handler;
- (void) subscribeByCDID:(LSCDID*)cdid subscriptionInfo:(NSArray*)subscriptions flagUnsubscribe:(BOOL)flagUnsibscribe replyHandler:(void (^)(BOOL result))handler;
- (void) getSubscriptionInfoArrayByCDID:(LSCDID*)cdid replyHandler:(void (^)(NSArray*))handler;
- (void) getUnwatchedEpisodesInfoArrayByCDID:(LSCDID*)cdid replyHandler:(void (^)(NSArray*))handler;
- (void) setUnwatchedEpisodesByCDID:(LSCDID*)cdid episodesUnwatched:(NSArray*)episodesUnwatched flagRemove:(BOOL)flagRemove replyHandler:(void (^)(BOOL result))handler;
- (void) getSnapshotsRequest:(void (^)(LSSnapshotInfo*))handler;

@end


//
// LSEpisodeInfo
//

@interface LSEpisodeInfo : NSObject
@property NSString* name;
@property NSString* originalName;
@property NSInteger number;
@property NSDate* dateTranslate;
@end


//
// LSShowInfo
//

@interface LSShowInfo : NSObject
// properties
@property NSString* title;
@property NSString* originalTitle;
@property NSInteger seasonNumber;
@property NSInteger year;
@property NSString* showID;
@property NSString* snapshot;
@property NSArray* episodes;
@property NSArray* episodesUnwatched;
@end


//
// LSSubscriptionInfo
//

@interface LSSubscriptionInfo : NSObject
// properties
@property NSString* showID;
@end


//
// LSEpisodeUnwatchedInfo
//

@interface LSEpisodeUnwatchedInfo : NSObject
@property NSString* idShow;
@property NSInteger numberSeason;
@property NSInteger numberEpisode;
@end


//
// LSSnapshotInfo
//

@interface LSSnapshotInfo : NSObject
@end
