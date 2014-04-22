//
//  JetPartialArray.h
//  LostSeries
//
//  Created by Grigory Zubankov on 22/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>


//
// JetArrayPartial
//

@interface JetArrayPartial : NSObject <NSFastEnumeration>

+ (JetArrayPartial*) arrayPartialWithArraySource:(NSArray*)arraySource ;
- (id) initWithArraySource:(NSArray*)arraySource;

- (NSInteger) indexSourceToTarget:(NSInteger)indexSource;
- (NSInteger) indexTargetToSource:(NSInteger)indexTarget;

- (BOOL) hasIndexSource:(NSInteger)indexSource;

- (void) addObjectByIndexSource:(NSInteger)indexSource;
- (void) mergeObjectsFromArrayPartial:(JetArrayPartial*)array;
- (void) subtractObjectsFromArrayPartial:(JetArrayPartial*)array;

- (void) removeObjectByIndexSource:(NSInteger)indexSource;
- (void) removeObjectByIndexTarget:(NSInteger)indexTarget;

- (NSInteger) count;
- (void) removeAllObjectes;
- (void) addAllObjects;

// operator []
- (id) objectAtIndexedSubscript:(NSUInteger)index;
- (void) setObject:(id)obj atIndexedSubscript:(NSUInteger)index;

@end
