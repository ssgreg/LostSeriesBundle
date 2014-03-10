//
//  LSControllerCollectionBase.h
//  LostSeries
//
//  Created by Grigory Zubankov on 04/03/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// UIKit
#import <UIKit/UIKit.h>


@interface LSControllerCollectionBase : UICollectionViewController

- (void) reloadData;
- (NSRange) rangeVisibleItems;

@property BOOL hiddenLoadingIndicator;

@end
