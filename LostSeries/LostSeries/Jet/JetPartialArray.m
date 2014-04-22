//
//  JetPartialArray.m
//  LostSeries
//
//  Created by Grigory Zubankov on 22/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "JetPartialArray.h"


//
// LSPartialArrayRecord
//

@interface LSPartialArrayRecord : NSObject
@property NSInteger indexSource;
@property NSInteger indexTarget;
@end

@implementation LSPartialArrayRecord
@synthesize indexSource;
@synthesize indexTarget;
@end


//
// JetArrayPartial
//

@implementation JetArrayPartial
{
  NSArray* theArraySource;
  //
  NSMutableArray* theRecord;
  NSMutableDictionary* theDictionaryIndexSourceToTarget;
}

+ (JetArrayPartial*) arrayPartialWithArraySource:(NSArray*)arraySource
{
  return [[JetArrayPartial alloc] initWithArraySource:arraySource];
}

- (id) initWithArraySource:(NSArray*)arraySource
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theArraySource = arraySource;
  theRecord = [NSMutableArray array];
  theDictionaryIndexSourceToTarget = [NSMutableDictionary dictionary];
  //
  return self;
}

- (NSInteger) indexSourceToTarget:(NSInteger)indexSource
{
  id object = [theDictionaryIndexSourceToTarget objectForKey:[NSNumber numberWithInteger:indexSource]];
  return object
    ? ((LSPartialArrayRecord*)object).indexTarget
    : NSNotFound;
}

- (NSInteger) indexTargetToSource:(NSInteger)indexTarget
{
  return ((LSPartialArrayRecord*)theRecord[indexTarget]).indexSource;
}

- (BOOL) hasIndexSource:(NSInteger)indexSource
{
  return [self indexSourceToTarget:indexSource] != NSNotFound;
}

- (void) addObjectByIndexSource:(NSInteger)indexSource
{
  NSAssert(![self hasIndexSource:indexSource], @"Index already exists");
  //
  LSPartialArrayRecord* record = [[LSPartialArrayRecord alloc] init];
  record.indexSource = indexSource;
  record.indexTarget = theRecord.count;
  //
  [theRecord addObject:record];
  theDictionaryIndexSourceToTarget[[NSNumber numberWithInteger:indexSource]] = record;
}

- (void) mergeObjectsFromArrayPartial:(JetArrayPartial*)array
{
  for (LSPartialArrayRecord* record in array->theRecord)
  {
    if (![self hasIndexSource:record.indexSource])
    {
      [self addObjectByIndexSource:record.indexSource];
    }
  }
}

- (void) subtractObjectsFromArrayPartial:(JetArrayPartial*)array
{
  for (LSPartialArrayRecord* record in array->theRecord)
  {
    if ([self hasIndexSource:record.indexSource])
    {
      [self removeObjectByIndexSource:record.indexSource];
    }
  }
}

- (void) removeObjectByIndexSource:(NSInteger)indexSource
{
  [self removeObjectByIndexTarget:[self indexSourceToTarget:indexSource]];
}

- (void) removeObjectByIndexTarget:(NSInteger)indexTarget
{
  NSNumber* numberSource = [NSNumber numberWithInteger:[self indexTargetToSource:indexTarget]];
  [theRecord removeObjectAtIndex:indexTarget];
  [theDictionaryIndexSourceToTarget removeObjectForKey:numberSource];
  // fix indexes
  for (NSInteger i = indexTarget; i < theRecord.count; ++i)
  {
    ((LSPartialArrayRecord*)theRecord[i]).indexTarget = i;
  }
}

- (NSInteger) count
{
  return theRecord.count;
}

- (void) removeAllObjectes
{
  [theRecord removeAllObjects];
  [theDictionaryIndexSourceToTarget removeAllObjects];
}

- (void) addAllObjects
{
  for (NSInteger i = 0; i < theArraySource.count; ++i)
  {
    [self addObjectByIndexSource:i];
  }
}

- (id) objectAtIndexedSubscript:(NSUInteger)index
{
  return theArraySource[[self indexTargetToSource:index]];
}

- (void) setObject:(id)obj atIndexedSubscript:(NSUInteger)index
{
  theRecord[index] = obj;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
  if (state->state >= theRecord.count)
  {
    return 0;
  }
  NSInteger indexSource = [self indexTargetToSource:state->state];
  __unsafe_unretained id obj = theArraySource[indexSource];
  state->itemsPtr = &obj;
  state->mutationsPtr = (uintptr_t*)(__bridge void*)theRecord;
  state->state++;
  //
  return 1;
}

@end
