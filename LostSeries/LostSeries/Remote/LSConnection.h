//
//  LSConnection.h
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// LS
#import "LSChannel.h"


//
// LSConnection
//

@interface LSConnection : NSObject

// factory methods
+ (LSConnection*) connection;

// init methods
- (id) init;

// interface
- (LSChannel*) createPriorityChannel;

@end
