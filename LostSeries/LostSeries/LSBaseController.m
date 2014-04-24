//
//  LSBaseController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 23/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSBaseController.h"


inline NSString* MakeIdController(NSString* parent, NSString* child)
{
  return [NSString stringWithFormat:@"%@.%@", parent, child];
}
