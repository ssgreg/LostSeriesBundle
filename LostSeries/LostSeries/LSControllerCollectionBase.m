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
  NSLog(@"%f",self.collectionView.contentSize.height);
  static BOOL useAnimationOnce = YES;
  if (theCollectionViewLoadingStub.hidden == flag)
  {
    return;
  }
  if (useAnimationOnce)
  {
    useAnimationOnce = NO;
    [UIView animateWithDuration:0.5 delay:.0 options:0 animations:^
    {
      theCollectionViewLoadingStub.alpha = 0;
    }
    completion:^(BOOL finished)
    {
      theCollectionViewLoadingStub.hidden = flag;
    }];
  }
  else
  {
    theCollectionViewLoadingStub.hidden = flag;
  }
  [self scrollToDefaultPosition];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  //
  [self createSearchBar];
  [self createCollectionViewLoadingStub];
  theRangeVisibleItems = NSMakeRange(0, 0);
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
  theCollectionViewLoadingStub = [[UILoadingView alloc] initWithFrame:self.collectionView.frame];
  [theCollectionViewLoadingStub setText:@"Loading..."];
  [self.view.viewForBaselineLayout addSubview:theCollectionViewLoadingStub];
  theCollectionViewLoadingStub.hidden = NO;
}

- (void) scrollToDefaultPosition
{
  [self.collectionView setContentOffset:CGPointMake(0, -20)];
}

- (void) fixScrollPositionOnSearchBar
{
  NSInteger itemsCount = [self.collectionView numberOfItemsInSection:0];
  if (!itemsCount)
  {
    return;
  }
  if (self.collectionView.contentOffset.y < -64)
  {
  }
  else if (self.collectionView.contentOffset.y < -42)
  {
    [self.collectionView setContentOffset:CGPointMake(0, -64) animated:YES];
  }
  else if (self.collectionView.contentOffset.y < -20)
  {
    [self.collectionView setContentOffset:CGPointMake(0, -20) animated:YES];
  }
}

- (void)searchBarTextDidChange:(NSString*)text
{
}


#pragma mark - UISearchBarDelegate implementation


- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
  [self searchBarTextDidChange:searchText];
  [searchBar becomeFirstResponder];
}


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
  [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
  [searchBar setText:@""];
  [self searchBarTextDidChange:@""];
  [searchBar setShowsCancelButton:NO animated:YES];
  [searchBar resignFirstResponder];
}


#pragma mark - UICollectionViewDataSource implementation


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  id cell = nil;
  if ([kind isEqual:UICollectionElementKindSectionHeader])
  {
    cell = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"MyHeader" forIndexPath:indexPath];
    // scroll position should be fixed once at start
    if (theFlagFixScrollPositionAtStart)
    {
      [self scrollToDefaultPosition];
      theFlagFixScrollPositionAtStart = NO;
    }
  }
  if ([kind isEqual:UICollectionElementKindSectionFooter])
  {
    cell = [self.collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"theFooter" forIndexPath:indexPath];
  }
  return cell;
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
