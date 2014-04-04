//
//  LSCDID.h
//  LostSeries
//
//  Created by Grigory Zubankov on 04/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>


//
// LSCDID
// Cross-Device Identifier
//

@interface LSCDID : NSObject

#pragma mark - Init Methods

- (id) initWithAnother:(LSCDID*)another;
- (id) initWithString:(NSString*)string;
- (id) initWithRaw:(NSArray*)array;

#pragma mark - Interface

- (void) merge:(LSCDID*)another;
- (NSString*) toString;

#pragma mark - Properties

@property NSArray* raw;

@end
