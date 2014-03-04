//
//  LSControllerCollectionBase.m
//  LostSeries
//
//  Created by Grigory Zubankov on 04/03/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSControllerCollectionBase.h"
//
#define MAX_VISIBLE_ITEMS_COUNT 15

@implementation LSControllerCollectionBase
{
  //
  NSRange theRangeVisibleItems;  
}

- (void) reloadData
{
  [self.collectionView reloadData];
  theRangeVisibleItems = NSMakeRange(0, MIN([self.collectionView numberOfItemsInSection:0], MAX_VISIBLE_ITEMS_COUNT));
}

- (NSRange) rangeVisibleItems
{
  NSArray* indexPaths = [self.collectionView indexPathsForVisibleItems];
  if (indexPaths.count)
  {
    NSInteger xmax = INT_MIN, xmin = NSNotFound;
    for (NSIndexPath* indexPath in indexPaths)
    {
      NSInteger x = indexPath.row;
      if (x < xmin) xmin = x;
      if (x > xmax) xmax = x;
    }
    theRangeVisibleItems = NSMakeRange(xmin, xmax - xmin + 1);
  }
  return theRangeVisibleItems;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  theRangeVisibleItems = NSMakeRange(NSNotFound, NSNotFound);
}

@end
