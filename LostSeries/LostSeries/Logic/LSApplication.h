//
//  LSApplication.h
//  LostSeries
//
//  Created by Grigory Zubankov on 10/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Cocoa
#import <Foundation/Foundation.h>


//
// LSApplication
//

@interface LSApplication : NSObject

+ (LSApplication*) singleInstance;

// init
- (id) init;

@property NSString* deviceToken;

@end
