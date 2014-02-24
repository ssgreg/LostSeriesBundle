//
//  LSServiceArtworkGetter.h
//  LostSeries
//
//  Created by Grigory Zubankov on 23/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSModelBase.h"


@class LSServiceArtworkGetter;

@protocol LSClientServiceArtworkGetters <NSObject>

- (BOOL) isInBackgroundForServiceArtworkGetter:(LSServiceArtworkGetter*)service;
- (NSRange) indexQueueForServiceArtworkGetter:(LSServiceArtworkGetter*)service;

@end


@protocol LSDataServiceArtworkGetter <LSShowAsyncBackendFacadeData, LSShowsShowsData>
@end


@interface LSServiceArtworkGetter : NSObject

- (id) initWithData:(id)data;
- (void) getArtworks;
- (void) addClient:(id<LSClientServiceArtworkGetters>)client;

@end


//
// Notifications
//

extern NSString* LSServiceArtworkGetterArtworkDidGetNotification; // artwork has been gotten
