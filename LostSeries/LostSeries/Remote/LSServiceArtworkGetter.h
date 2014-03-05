//
//  LSServiceArtworkGetter.h
//  LostSeries
//
//  Created by Grigory Zubankov on 23/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// LS
#import "LSModelBase.h"
// forwards
@class LSServiceArtworkGetter;
@class LSArtworkGetterImpl;


//
// LSDelegateArtworkGetterImpl
//

@protocol LSDelegateArtworkGetterImpl <NSObject>

- (NSInteger) nextIndexForServiceArtworkGetterImpl:(LSArtworkGetterImpl*)object;
- (void) serviceArtworkGetter:(LSArtworkGetterImpl*)object didGetArtworkAtIndex:(NSInteger)index;

@end


//
// LSArtworkGetterImpl
//

@interface LSArtworkGetterImpl : NSObject
- (id) initWithData:(id)data;
- (void) startWithDelegate:(id<LSDelegateArtworkGetterImpl>)delegate;
- (void) stop;
@end


//
// LSServiceArtworkGetterPriority
//

typedef enum
{
  LSServiceArtworkGetterPriorityLow,
  LSServiceArtworkGetterPriorityNormal,
  LSServiceArtworkGetterPriorityHigh
} LSServiceArtworkGetterPriority;


//
// LSClientServiceArtworkGetters
//

@protocol LSClientServiceArtworkGetters <NSObject>

@required
- (LSServiceArtworkGetterPriority) priorityForServiceArtworkGetter:(LSServiceArtworkGetter*)service;
- (NSInteger) nextIndexForServiceArtworkGetter:(LSServiceArtworkGetter*)service;

@optional
- (void) serviceArtworkGetter:(LSServiceArtworkGetter*)service didGetArtworkAtIndex:(NSInteger)index;

@end


//
// LSDataServiceArtworkGetter
//

@protocol LSDataServiceArtworkGetter <LSDataBaseFacadeAsyncBackend, LSDataBaseShows>
@end


//
// LSServiceArtworkGetter
//

@interface LSServiceArtworkGetter : NSObject <LSDelegateArtworkGetterImpl>

- (void) start;
- (void) stop;

- (id) initWithData:(id)data;
- (void) addClient:(id<LSClientServiceArtworkGetters>)client;

@end
