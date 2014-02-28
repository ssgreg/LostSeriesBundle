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


//
// LSClientServiceArtworkGetters
//

@protocol LSClientServiceArtworkGetters <NSObject>

@required
- (BOOL) isInBackgroundForServiceArtworkGetter:(LSServiceArtworkGetter*)service;
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

@interface LSServiceArtworkGetter : NSObject

- (id) initWithData:(id)data;
- (void) getArtworks;
- (void) addClient:(id<LSClientServiceArtworkGetters>)client;

@end
