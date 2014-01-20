//
//  LSBatchArtworkGetter.m
//  LostSeries
//
//  Created by Grigory Zubankov on 19/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSBatchArtworkGetter.h"


//
// LSBatchArtworkGetter
//

@interface LSBatchArtworkGetter ()
{
@private
  id<LSBatchArtworkGetterDelegate> theDelegate;
  NSMutableDictionary* theDoneDictionary;
  NSInteger theNextRegularItemIndex;
}

- (BOOL) getNextItemAsync;
- (void) callDidGetArtwork:(NSData*)data index:(NSInteger)index;
- (void) getArtworkAsyncByIndex:(NSInteger)index;
- (BOOL) tryGetNextItemFromPriorities;
- (BOOL) tryGetNextItemFromRegulars;

@end

@implementation LSBatchArtworkGetter

static NSInteger const numberOfItemsGettingSimultaniously = 5;
static NSString* const keyShowInfo = @"showInfo";
static NSString* const keyIsRequested = @"isRequested";


+ (LSBatchArtworkGetter*) artworkGetterWithDelegate:(id<LSBatchArtworkGetterDelegate>)delegate
{
  return [[LSBatchArtworkGetter alloc] initWithDelegate:delegate];
}

- (id) initWithDelegate:(id<LSBatchArtworkGetterDelegate>)delegate
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theDelegate = delegate;
  theDoneDictionary = [NSMutableDictionary dictionary];
  theNextRegularItemIndex = 0;
  //
  for (NSInteger i = 0; i < numberOfItemsGettingSimultaniously; ++i)
  {
    [self getNextItemAsync];
  }
  //
  return self;
}

- (BOOL) getNextItemAsync
{
  if (![self tryGetNextItemFromPriorities])
  {
    return [self tryGetNextItemFromRegulars];
  }
  return YES;
}

- (void) getArtworkAsyncByIndex:(NSInteger)index
{
  __weak typeof(self) weakSelf = self;
  void (^completionHandler)(NSData*) = ^(NSData* data)
  {
    [weakSelf callDidGetArtwork:data index:index];
    [weakSelf getNextItemAsync];
  };
  [theDelegate getArtworkAsyncForIndex:index completionHandler:completionHandler];
}

- (void) callDidGetArtwork:(NSData*)data index:(NSInteger)index
{
  [theDelegate didGetArtwork:data forIndex:index];
}

- (BOOL) tryGetNextItemFromPriorities
{
  NSArray* priorities = [theDelegate getPriorityWindow];
  for (NSNumber* index in priorities)
  {
    if (![theDoneDictionary objectForKey:index])
    {
      theDoneDictionary[index] = [NSNumber numberWithBool:YES];
      [self getArtworkAsyncByIndex:index.integerValue];
      return YES;
    }
  }
  return NO;
}

- (BOOL) tryGetNextItemFromRegulars
{
  for (; theNextRegularItemIndex < [theDelegate getNumberOfItems]; ++theNextRegularItemIndex)
  {
    NSNumber* index = [NSNumber numberWithInteger:theNextRegularItemIndex];
    if (![theDoneDictionary objectForKey:index])
    {
      theDoneDictionary[index] = [NSNumber numberWithBool:YES];
      [self getArtworkAsyncByIndex:index.integerValue];
      ++theNextRegularItemIndex;
      return YES;
    }
  }
  return NO;
}

@end
