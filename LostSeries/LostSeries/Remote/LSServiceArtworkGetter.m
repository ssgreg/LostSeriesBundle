//
//  LSServiceArtworkGetter.m
//  LostSeries
//
//  Created by Grigory Zubankov on 23/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSServiceArtworkGetter.h"


//
// LSArtworkGetterImpl
//

@implementation LSArtworkGetterImpl
{
  id<LSDataServiceArtworkGetter> theData;
  NSMutableDictionary* theDones;
  id<LSDelegateArtworkGetterImpl> theDelegate;
}

- (id) initWithData:(id)data
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theData = (id<LSDataServiceArtworkGetter>)data;
  theDones = [NSMutableDictionary dictionary];
  //
  return self;
}

- (void) startWithDelegate:(id<LSDelegateArtworkGetterImpl>)delegate
{
  theDelegate = delegate;
  [self nextArtworkAsync];
//  [self nextArtworkAsync];
//  [self nextArtworkAsync];
//  [self nextArtworkAsync];
}

- (void) stop
{
  theDelegate = nil;
}

- (void) nextArtworkAsync
{
  NSInteger index = [self indexNext];
  if (index >= theData.shows.count)
  {
    return;
  }
  __weak typeof(self) weakSelf = self;
  LSShowAlbumCellModel* modelCell = [theData.shows objectAtIndex:index];
  //
  [[theData backendFacade] getArtworkByShowInfo:modelCell.showInfo thumbnail:YES replyHandler:^(NSData* dataArtwork)
  {
    typeof (self) strongSelf = weakSelf;
    if (strongSelf)
    {
      [strongSelf nextArtworkAsync];
      modelCell.artwork = [UIImage imageWithData:dataArtwork];
      if (strongSelf->theDelegate)
      {
        [strongSelf->theDelegate serviceArtworkGetter:strongSelf didGetArtworkAtIndex:index];
      }
    }
  }];
  theDones[[NSNumber numberWithInteger:index]] = @YES;
}

- (NSInteger) indexNext
{
  for (;;)
  {
    NSInteger index = [theDelegate nextIndexForServiceArtworkGetterImpl:self];
    if (![theDones objectForKey:[NSNumber numberWithInteger:index]])
    {
      return index;
    }
  }
  return NSNotFound;
}

@end


//
// LSServiceArtworkGetter
//

@implementation LSServiceArtworkGetter
{
  LSArtworkGetterImpl* theServiceImpl;
  id<LSDataServiceArtworkGetter> theData;
  NSMutableArray* theClients;
}

- (id) initWithData:(id)data
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theData = (id<LSDataServiceArtworkGetter>)data;
  theClients = [NSMutableArray array];
  //
  return self;
}

- (void) start
{
  [self stop];
  theServiceImpl = [[LSArtworkGetterImpl alloc] initWithData:theData];
  [theServiceImpl startWithDelegate:self];
}

- (void) stop
{
  [theServiceImpl stop];
  theServiceImpl = nil;
}

- (void) addClient:(id<LSClientServiceArtworkGetters>)client
{
  [theClients addObject:client];
}

- (NSArray*) sortClientsByPriority
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

- (NSInteger) indexNext
{
  NSArray* clientsByPriority = [self sortClientsByPriority];
  for (id<LSClientServiceArtworkGetters> client in clientsByPriority)
  {
    NSInteger index = [client nextIndexForServiceArtworkGetter:self];
    if (index != NSNotFound)
    {
      return index;
    }
  }
  return NSNotFound;
}

#pragma mark - LSDelegateArtworkGetterImpl

- (NSInteger) nextIndexForServiceArtworkGetterImpl:(LSArtworkGetterImpl*)object
{
  return [self indexNext];
}

- (void) serviceArtworkGetter:(LSArtworkGetterImpl*)object didGetArtworkAtIndex:(NSInteger)index
{
  // notify clients
  for (id<LSClientServiceArtworkGetters> client in theClients)
  {
    if ([client respondsToSelector:@selector(serviceArtworkGetter:didGetArtworkAtIndex:)])
    {
      [client serviceArtworkGetter:self didGetArtworkAtIndex:index];
    }
  }
}

@end
