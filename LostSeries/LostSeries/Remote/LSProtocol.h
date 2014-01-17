//
//  LSProtocol.h
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// LS
#import "LSChannel.h"


// forwards
@class LSShowInfo;


//
// LSProtocol
//

@interface LSProtocol : NSObject

// factory methods
+ (LSProtocol*) protocolWithChannel:(LSChannel*)channel;

// init methods
- (id) initWithChannel:(LSChannel*)channel;

// interface
- (void) getShowInfoArray:(void (^)(NSArray*))handler;
- (void) getArtwork:(LSShowInfo*)showInfo completionHandler:(void (^)(NSData*))handler;

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
