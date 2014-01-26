//
//  LSBatchArtworkGetter.h
//  LostSeries
//
//  Created by Grigory Zubankov on 19/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// LS
#import "LSAsyncBackendFacade.h"


//
// LSBatchArtworkGetterDelegate
//

@protocol LSBatchArtworkGetterDelegate <NSObject>

- (NSInteger) getNumberOfItems;
- (NSArray*) getPriorityWindow;
- (void) getArtworkAsyncForIndex:(NSInteger)index completionHandler:(void (^)(NSData*))handler;
- (void) didGetArtwork:(NSData*)data forIndex:(NSInteger)index;

@end


//
// LSBatchArtworkGetter
//

@interface LSBatchArtworkGetter : NSObject

#pragma mark - Factory Methods
+ (LSBatchArtworkGetter*) artworkGetterWithDelegate:(id<LSBatchArtworkGetterDelegate>)delegate;

#pragma mark - Init Methods
- (id) initWithDelegate:(id<LSBatchArtworkGetterDelegate>)delegate;

@end