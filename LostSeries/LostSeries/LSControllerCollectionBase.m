//
//  LSControllerCollectionBase.m
//  LostSeries
//
//  Created by Grigory Zubankov on 04/03/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSControllerCollectionBase.h"
#import <UIComponents/UILoadingView.h>
//
#define MAX_VISIBLE_ITEMS_COUNT 15


//
// LSControllerCollectionBase
//

@implementation LSControllerCollectionBase
{
  UILoadingView* theCollectionViewLoadingStub;
  //
  NSRange theRangeVisibleItems;  
}

- (void) reloadData
{
  [self.collectionView reloadData];
  //
  NSInteger itemsCount = [self.collectionView numberOfItemsInSection:0];
  theRangeVisibleItems = NSMakeRange(0, MIN(itemsCount, MAX_VISIBLE_ITEMS_COUNT));
  self.hiddenLoadingIndicator = itemsCount != 0;
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

- (BOOL) hiddenLoadingIndicator
{
  return theCollectionViewLoadingStub.hidden;
}

- (void) setHiddenLoadingIndicator:(BOOL)flag
{
  theCollectionViewLoadingStub.hidden = flag;
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  //
  [self createCollectionViewLoadingStub];
  theRangeVisibleItems = NSMakeRange(NSNotFound, NSNotFound);
}

- (void) createCollectionViewLoadingStub
{
  CGRect rect = self.collectionView.frame;
  // fix frame due the reason that frame takes height of tab bar and navigation bar
  rect.size.height -= self.tabBarController.tabBar.frame.size.height;
  rect.size.height -= self.navigationController.navigationBar.frame.size.height;
  //
  theCollectionViewLoadingStub = [[UILoadingView alloc] initWithFrame:rect];
  [theCollectionViewLoadingStub setText:@"Loading..."];
  [self.collectionView.viewForBaselineLayout addSubview:theCollectionViewLoadingStub];
  theCollectionViewLoadingStub.hidden = NO;
}

@end
