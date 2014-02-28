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

- (void) getArtworks
{
  [self nextArtworkAsync];
//  [self nextArtworkAsync];
//  [self nextArtworkAsync];
//  [self nextArtworkAsync];
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
    [weakSelf nextArtworkAsync];
    modelCell.artwork = [UIImage imageWithData:dataArtwork];
    // notify clients
    for (id<LSClientServiceArtworkGetters> client in theClients)
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
    if (index != INT_MAX)
    {
      NSLog(@"%@ - %ld", NSStringFromClass([client class]), index);
      return index;
    }
  }
  return INT_MAX;
}

- (NSInteger) nextIndexForClient:(id<LSClientServiceArtworkGetters>)client
{
  for (NSInteger index = 0; index != INT_MAX;)
  {
    index = [client nextIndexForServiceArtworkGetter:self];
    if (![theDones objectForKey:[NSNumber numberWithInteger:index]])
    {
      return index;
    }
  }
  return INT_MAX;
}

- (NSArray*) sortClientByPriority
{
  return [theClients sortedArrayUsingComparator:^(id left, id right)
  {
    LSServiceArtworkGetterPriority priorityLeft = [left isInBackgroundForServiceArtworkGetter:self];
    LSServiceArtworkGetterPriority priorityRight = [right isInBackgroundForServiceArtworkGetter:self];
    return priorityLeft == priorityRight
      ? NSOrderedSame
      : priorityLeft > priorityRight
        ? NSOrderedAscending
        : NSOrderedDescending;
  }];
}

@end
