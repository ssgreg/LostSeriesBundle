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
  //
  UISearchBar* theSearchBar;
  BOOL theFlagFixScrollPositionAtStart;
}

- (void) reloadData
{
  [self.collectionView reloadData];
//  [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
  //
  NSInteger itemsCount = [self.collectionView numberOfItemsInSection:0];
  theRangeVisibleItems = NSMakeRange(0, MIN(itemsCount, MAX_VISIBLE_ITEMS_COUNT));
  self.hiddenLoadingIndicator = itemsCount != 0;
  //
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
  if (theCollectionViewLoadingStub.hidden == flag)
  {
    return;
  }
  [UIView animateWithDuration:0.5 delay:.0 options:0 animations:^
  {
    theCollectionViewLoadingStub.alpha = 0;
  }
  completion:^(BOOL finished)
  {
    theCollectionViewLoadingStub.hidden = flag;
  }];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  //
  [self createSearchBar];
  [self createCollectionViewLoadingStub];
  theRangeVisibleItems = NSMakeRange(NSNotFound, NSNotFound);
  theFlagFixScrollPositionAtStart = YES;
}

- (void) createSearchBar
{
  theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.collectionView.frame.size.width, 44)];
  [self.collectionView addSubview:theSearchBar];
  theSearchBar.delegate = self;
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
  [self.view.viewForBaselineLayout addSubview:theCollectionViewLoadingStub];
  theCollectionViewLoadingStub.hidden = NO;

}

- (void)viewDidAppear:(BOOL)animated
{
  // scroll position should be fixed once at start
  if (theFlagFixScrollPositionAtStart)
  {
    [self scrollToDefaultPosition];
    theFlagFixScrollPositionAtStart = NO;
  }
}

- (void) scrollToDefaultPosition
{
  [self.collectionView setContentOffset:CGPointMake(0, 44)];
}

- (void) fixScrollPositionOnSearchBar
{
  NSInteger itemsCount = [self.collectionView numberOfItemsInSection:0];
  if (!itemsCount)
  {
    return;
  }
  if (self.collectionView.contentOffset.y < 22)
  {
    [self.collectionView setContentOffset:CGPointMake(0, 0) animated:YES];
  }
  else if (self.collectionView.contentOffset.y < 44)
  {
    [self.collectionView setContentOffset:CGPointMake(0, 44) animated:YES];
  }
}


//- (void)keyboardWillHide:(NSNotification *)notification
//{
//    peoplePickerController.navigationBar.hidden = YES;
//}
//
- (void)hideNavbarAndKeepHidden
{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
//
//- (void)dealloc
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [super dealloc];
//}


#pragma mark - UICollectionViewDataSource implementationr


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  id header = nil;
  if ([kind isEqual:UICollectionElementKindSectionHeader])
  {
    header = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"MyHeader" forIndexPath:indexPath];
  }
  return header;
}


#pragma mark - UICollectionViewDelegate implementation


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  [self fixScrollPositionOnSearchBar];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  if (!decelerate)
  {
    [self fixScrollPositionOnSearchBar];
  }
}

@end
