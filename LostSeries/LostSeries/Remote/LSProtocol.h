//
//  LSProtocol.h
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>


// forwards
@class LSShowInfo;


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
- (void) getArtworkByShowInfo:(LSShowInfo*)showInfo replyHandler:(void (^)(NSData*))handler;

@end


//
// LSShowInfo
//

@interface LSShowInfo : NSObject

// factory methods
+ (LSShowInfo*) showInfo;
+ (LSShowInfo*) showInfoWithTitle:(NSString*)title
                    originalTitle:(NSString*)originalTitle
                     seasonNumber:(NSInteger)seasonNumber
                         snapshot:(NSString*)snapshot;

@property NSString* title;
@property NSString* originalTitle;
@property NSInteger seasonNumber;
@property NSString* snapshot;

- (id) initWithTitle:(NSString*)title
       originalTitle:(NSString*)originalTitle
        seasonNumber:(NSInteger)seasonNumber
            snapshot:(NSString*)snapshot;


@end
