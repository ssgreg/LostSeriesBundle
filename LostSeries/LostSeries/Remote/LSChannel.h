//
//  LSChannel.h
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// Protobuf
#include <Protobuf.Generated/LostSeriesProtocol.h>


//
// LSChannel
//

@interface LSChannel : NSObject

// factory methods
+ (LSChannel*) serverChannelWithSendHandler:(void (^)(LS::Message const&, id))handler;

// init methods
- (id) initWithSendHandler:(void (^)(LS::Message const&, id))handler;

// interface
- (void) send:(LS::Message const&)request completionHandler:(void (^)(LS::Message const& reply))handler;

@end
