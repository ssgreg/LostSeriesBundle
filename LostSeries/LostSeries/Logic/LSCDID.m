//
//  LSCDID.m
//  LostSeries
//
//  Created by Grigory Zubankov on 04/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSCDID.h"


//
// LSCDID
//

@implementation LSCDID
{
  NSArray* theCDID;
}

@synthesize raw = theCDID;

- (id) initWithAnother:(LSCDID*)another
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theCDID = another.raw;
  //
  return self;
}

- (id) initWithString:(NSString*)string
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theCDID = [NSArray arrayWithObject:string];
  //
  return self;
}

- (id) initWithRaw:(NSArray*)array
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theCDID = array;
  //
  return self;
}

- (void) merge:(LSCDID*)another
{
  NSMutableSet* temp = [NSMutableSet setWithArray:theCDID];
  [temp addObjectsFromArray:another.raw];
  theCDID = [temp allObjects];
}

- (NSString*) toString
{
  NSString* result = @"";
  NSString* divider = @"";
  for (NSString* idDevice in theCDID)
  {
    result = [NSString stringWithFormat:@"%@%@%@", result, divider, idDevice, nil];
    divider = @",";
  }
  return result;
}

@end
