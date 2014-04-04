//
//  LSRegistryControllers.m
//  LostSeries
//
//  Created by Grigory Zubankov on 04/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSRegistryControllers.h"


//
// LSRegistryControllers
//

@implementation LSRegistryControllers
{
  NSMutableDictionary* theControllersByIdentifiers;
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theControllersByIdentifiers = [NSMutableDictionary dictionary];
  //
  return self;
}

- (void) registerController:(id)controller withIdentifier:(NSString*)identifier
{
  NSAssert(identifier.length, @"Bad identifier");
  NSAssert(![theControllersByIdentifiers objectForKey:identifier], @"Bad invariant.");
  theControllersByIdentifiers[identifier] = controller;
}

- (void) removeController:(NSString*)identifier
{
  NSAssert(identifier.length, @"Bad identifier");
  NSAssert([theControllersByIdentifiers objectForKey:identifier], @"Bad invariant.");
  [theControllersByIdentifiers removeObjectForKey:identifier];
}

- (id) findControllerByIdentifier:(NSString*)identifier
{
  return theControllersByIdentifiers[identifier];
}

@end
