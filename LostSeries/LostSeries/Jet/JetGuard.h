//
//  JetGuard.h
//  LostSeries
//
//  Created by Grigory Zubankov on 06/05/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>


//
// JetGuard
//

@interface JetGuard : NSObject

+ (JetGuard*) guard;
- (id) init;

- (BOOL) lock;
- (void) unlock;
- (BOOL) locked;

@end
