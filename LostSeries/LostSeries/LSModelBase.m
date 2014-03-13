//
//  LSModelBase.m
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSModelBase.h"
#import "CachingServer/LSCachingServer.h"


//
// LSArrayPartial
//

@implementation LSArrayPartial
{
  NSArray* theArraySource;
  //
  NSMutableArray* theArrayTarget;
  NSMutableArray* theArrayIndexTargetToSource;
  NSMutableDictionary* theDictionaryIndexSourceToTarget;
}

+ (LSArrayPartial*) arrayPartialWithArraySource:(NSArray*)arraySource
{
  return [[LSArrayPartial alloc] initWithArraySource:arraySource];
}

- (id) initWithArraySource:(NSArray*)arraySource
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theArraySource = arraySource;
  theArrayTarget = [NSMutableArray array];
  theArrayIndexTargetToSource = [NSMutableArray array];
  theDictionaryIndexSourceToTarget = [NSMutableDictionary dictionary];
  //
  return self;
}

- (NSInteger) indexSourceToTarget:(NSInteger)indexSource
{
  id numberTarget = [theDictionaryIndexSourceToTarget objectForKey:[NSNumber numberWithInteger:indexSource]];
  return numberTarget
    ? ((NSNumber*)numberTarget).integerValue
    : NSNotFound;
}

- (NSInteger) indexTargetToSource:(NSInteger)indexTarget
{
  return ((NSNumber*)theArrayIndexTargetToSource[indexTarget]).integerValue;
}

- (BOOL) hasIndexSource:(NSInteger)indexSource
{
  return [self indexSourceToTarget:indexSource] != NSNotFound;
}

- (void) addObjectByIndexSource:(NSInteger)indexSource
{
  [theArrayTarget addObject:theArraySource[indexSource]];
  // indexes
  NSNumber* numberSource = [NSNumber numberWithInteger:indexSource];
  [theArrayIndexTargetToSource addObject:numberSource];
  theDictionaryIndexSourceToTarget[numberSource] = [NSNumber numberWithInteger:theArrayTarget.count - 1];
}

- (void) mergeObjectsFromArrayPartial:(LSArrayPartial*)array
{
  for (id object in array->theArrayIndexTargetToSource)
  {
    NSInteger indexSource = ((NSNumber*)object).integerValue;
    if (![self hasIndexSource:indexSource])
    {
      [self addObjectByIndexSource:indexSource];
    }
  }
}

- (void) removeObjectByIndexSource:(NSInteger)indexSource
{
  [self removeObjectByIndexTarget:[self indexSourceToTarget:indexSource]];
}

- (void) removeObjectByIndexTarget:(NSInteger)indexTarget
{
  [theArrayTarget removeObjectAtIndex:indexTarget];
  // indexes
  NSNumber* numberSource = [NSNumber numberWithInteger:[self indexTargetToSource:indexTarget]];
  [theDictionaryIndexSourceToTarget removeObjectForKey:numberSource];
  [theArrayIndexTargetToSource removeObjectAtIndex:indexTarget];
}

- (NSInteger) count
{
  return theArrayTarget.count;
}

- (void) removeAllObjectes
{
  [theArrayTarget removeAllObjects];
  [theArrayIndexTargetToSource removeAllObjects];
  [theDictionaryIndexSourceToTarget removeAllObjects];
}

- (id) objectAtIndexedSubscript:(NSUInteger)index
{
  return theArrayTarget[index];
}

- (void) setObject:(id)obj atIndexedSubscript:(NSUInteger)index
{
  theArrayTarget[index] = obj;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
  if (state->state >= theArrayTarget.count)
  {
    return 0;
  }
  __unsafe_unretained id obj = [theArrayTarget objectAtIndex:state->state];
  state->itemsPtr = &obj;
  state->mutationsPtr = (uintptr_t*)(__bridge void*)theArrayTarget;
  state->state++;
  //
  return 1;
}

@end


//
// LSModelShowsLists
//

@implementation LSModelShowsLists
{
  NSArray* theShows;
  LSArrayPartial* theShowsFollowing;
  LSArrayPartial* theShowsSelected;
}

@synthesize shows = theShows;
@synthesize showsFollowing = theShowsFollowing;
@synthesize showsSelected = theShowsSelected;

- (id) initWithShows:(NSArray*)shows
{
  if (!(self = [super init]))
  {
    return Nil;
  }
  theShows = shows;
  theShowsFollowing = [LSArrayPartial arrayPartialWithArraySource:theShows];
  theShowsSelected = [LSArrayPartial arrayPartialWithArraySource:theShows];
  return self;
}

@end



//
// LSShowAlbumCellModel
//

@implementation LSShowAlbumCellModel
@end


//
// LSModelBase
//

@implementation LSModelBase
{
  LSCachingServer* theCachingServer;
  LSAsyncBackendFacade* theBackendFacade;
  //
  NSArray* theShowsRaw;
  NSArray* theShowsFavoriteRaw;
  //
  BOOL theSelectionModeFlag;
  LSModelShowsLists* theModelShowsLists;
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theCachingServer = [[LSCachingServer alloc] init];
  theBackendFacade = [LSAsyncBackendFacade backendFacade];
  //
  theSelectionModeFlag = NO;
  return self;
}

- (NSArray*) shows
{
  return theModelShowsLists.shows;
}

- (LSArrayPartial*) showsFollowing
{
  return theModelShowsLists.showsFollowing;
}

- (LSArrayPartial*) showsSelected
{
  return theModelShowsLists.showsSelected;
}

@synthesize modelShowsLists = theModelShowsLists;
@synthesize showsRaw = theShowsRaw;
@synthesize showsFavoriteRaw = theShowsFavoriteRaw;
@synthesize selectionModeActivated = theSelectionModeFlag;
@synthesize backendFacade = theBackendFacade;

@end
