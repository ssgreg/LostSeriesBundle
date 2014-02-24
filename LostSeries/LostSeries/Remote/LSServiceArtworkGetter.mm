//
//  LSServiceArtworkGetter.m
//  LostSeries
//
//  Created by Grigory Zubankov on 23/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSServiceArtworkGetter.h"

@interface MyClass : NSObject <NSFastEnumeration>
@end

@implementation MyClass
{
  __unsafe_unretained NSMutableArray* theInternalItems;
}

- (id) init
{
  self = [super init];
  theInternalItems = [NSMutableArray array];
  [theInternalItems addObject:[NSNumber numberWithBool:YES]];
  [theInternalItems addObject:[NSNumber numberWithBool:NO]];
  return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len;
{
  if (state->state >= theInternalItems.count)
  {
      return 0;
  }
  __unsafe_unretained id obj = [theInternalItems objectAtIndex:state->state];
//  state->itemsPtr = (__unsafe_unretained)[theInternalItems objectAtIndex:state->state];
  state->state = theInternalItems.count;
  state->mutationsPtr = (uintptr_t*)(__bridge void*)self;
   
  return theInternalItems.count;
}

@end


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
  MyClass* myClass = [[MyClass alloc] init];
  
  for (id test in myClass)
  {
    NSLog(@"%d", ((NSNumber*)test).boolValue);
  }
  
  
  
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
    [[NSNotificationCenter defaultCenter] postNotificationName:LSServiceArtworkGetterArtworkDidGetNotification object:[NSNumber numberWithInteger:index]];
  }];
  theDones[[NSNumber numberWithInteger:index]] = @YES;
}

- (NSInteger) nextArtworkIndex
{
  // enumerate non-background clients at first
  for (id<LSClientServiceArtworkGetters> client in theClients)
  {
    if (![client isInBackgroundForServiceArtworkGetter:self])
    {
      NSLog(@"!back");
      NSRange range = [client indexQueueForServiceArtworkGetter:self];
      NSInteger index = [self nextInRange:range];
      if (index != INT_MAX)
      {
        return index;
      }
    }
  }
  // enumerate background clients at last
  for (id<LSClientServiceArtworkGetters> client in theClients)
  {
    if ([client isInBackgroundForServiceArtworkGetter:self])
    {
      NSLog(@"back");
      NSRange range = [client indexQueueForServiceArtworkGetter:self];
      NSInteger index = [self nextInRange:range];
      if (index != INT_MAX)
      {
        return index;
      }
    }
  }
  return INT_MAX;
}

- (NSInteger) nextInRange:(NSRange)range
{
  range = NSIntersectionRange(range, NSMakeRange(0, theData.shows.count));
  for (NSInteger loc = range.location; NSLocationInRange(loc, range); ++loc)
  {
    if (![theDones objectForKey:[NSNumber numberWithInteger:loc]])
    {
      return loc;
    }
  }
  return INT_MAX;
}

@end


//
// Notifications
//

NSString* LSServiceArtworkGetterArtworkDidGetNotification = @"LSServiceArtworkGetterArtworkDidGetNotification";

