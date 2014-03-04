//
//  LSServiceArtworkGetter.m
//  LostSeries
//
//  Created by Grigory Zubankov on 23/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSServiceArtworkGetter.h"


//
// LSServiceArtworkGetter
//

@implementation LSServiceArtworkGetter
{
  id<LSDataServiceArtworkGetter> theData;
  NSMutableArray* theClients;
  NSMutableDictionary* theDones;
}

- (id) initWithData:(id)data
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theData = (id<LSDataServiceArtworkGetter>)data;
  theClients = [NSMutableArray array];
  theDones = [NSMutableDictionary dictionary];
  return self;
}

- (void) start
{
  [self nextArtworkAsync];
//  [self nextArtworkAsync];
//  [self nextArtworkAsync];
//  [self nextArtworkAsync];
}

- (void) stop
{
  
}

- (void) addClient:(id<LSClientServiceArtworkGetters>)client
{
  [theClients addObject:client];
}

- (void) nextArtworkAsync
{
  NSInteger index = [self nextArtworkIndex];
  if (index >= theData.shows.count)
  {
    return;
  }
  __weak typeof(self) weakSelf = self;
  LSShowAlbumCellModel* modelCell = [theData.shows objectAtIndex:index];
  //
  [[theData backendFacade] getArtworkByShowInfo:modelCell.showInfo replyHandler:^(NSData* dataArtwork)
  {
    typeof (self) strongSelf = weakSelf;
    if (!strongSelf)
    {
      return;
    }
    [strongSelf nextArtworkAsync];
    modelCell.artwork = [UIImage imageWithData:dataArtwork];
    // notify clients
    for (id<LSClientServiceArtworkGetters> client in strongSelf->theClients)
    {
      if ([client respondsToSelector:@selector(serviceArtworkGetter:didGetArtworkAtIndex:)])
      {
        [client serviceArtworkGetter:self didGetArtworkAtIndex:index];
      }
    }
  }];
  theDones[[NSNumber numberWithInteger:index]] = @YES;
}

- (NSInteger) nextArtworkIndex
{
  NSArray* clientsByPriority = [self sortClientByPriority];
  for (id<LSClientServiceArtworkGetters> client in clientsByPriority)
  {
      NSLog(@"%@", NSStringFromClass([client class]));
  }
  for (id<LSClientServiceArtworkGetters> client in clientsByPriority)
  {
    NSInteger index = [self nextIndexForClient:client];
    NSLog(@"%@ - %ld", NSStringFromClass([client class]), index);
    if (index != NSNotFound)
    {
      NSLog(@"%@ - %ld", NSStringFromClass([client class]), index);
      return index;
    }
  }
  return NSNotFound;
}

- (NSInteger) nextIndexForClient:(id<LSClientServiceArtworkGetters>)client
{
  for (NSInteger index = 0; index != NSNotFound;)
  {
    index = [client nextIndexForServiceArtworkGetter:self];
    if (![theDones objectForKey:[NSNumber numberWithInteger:index]])
    {
      return index;
    }
  }
  return NSNotFound;
}

- (NSArray*) sortClientByPriority
{
  return [theClients sortedArrayUsingComparator:^(id left, id right)
  {
    LSServiceArtworkGetterPriority priorityLeft = [left priorityForServiceArtworkGetter:self];
    LSServiceArtworkGetterPriority priorityRight = [right priorityForServiceArtworkGetter:self];
    return priorityLeft == priorityRight
      ? NSOrderedSame
      : priorityLeft > priorityRight
        ? NSOrderedAscending
        : NSOrderedDescending;
  }];
}

@end
