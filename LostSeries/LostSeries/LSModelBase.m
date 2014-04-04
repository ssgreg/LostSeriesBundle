//
//  LSModelBase.m
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSModelBase.h"
#import "CachingServer/LSCachingServer.h"


@interface LSPartialArrayRecord : NSObject
@property NSInteger indexSource;
@property NSInteger indexTarget;
@end

@implementation LSPartialArrayRecord
@synthesize indexSource;
@synthesize indexTarget;
@end


//
// LSArrayPartial
//

@implementation LSArrayPartial
{
  NSArray* theArraySource;
  //
  NSMutableArray* theRecord;
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
  //
  LSPartialArrayRecord* record = [[LSPartialArrayRecord alloc] init];
  record.indexSource = indexSource;
  record.indexTarget = theRecord.count;
  //
  [theRecord addObject:record];
  theDictionaryIndexSourceToTarget[[NSNumber numberWithInteger:indexSource]] = record;
}

- (void) mergeObjectsFromArrayPartial:(LSArrayPartial*)array
{
  for (LSPartialArrayRecord* record in array->theRecord)
  {
    if (![self hasIndexSource:record.indexSource])
    {
      [self addObjectByIndexSource:record.indexSource];
    }
  }
}

- (void) subtractObjectsFromArrayPartial:(LSArrayPartial*)array
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
  BOOL theFollowingModeFlag;
  LSModelShowsLists* theModelShowsLists;
  //
  LSShowAlbumCellModel* theShowForDetails;
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
@synthesize followingModeFollow = theFollowingModeFlag;
@synthesize backendFacade = theBackendFacade;
@synthesize showForDetails = theShowForDetails;

@end
