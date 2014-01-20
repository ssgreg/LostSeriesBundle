//
//  LSViewController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 09/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// UIKit
#import <UIKit/UIKit.h>
// LS
#import "Remote/LSBatchArtworkGetter.h"


//
// LSViewController
//

@interface LSViewController : UIViewController<UICollectionViewDataSource, LSBatchArtworkGetterDelegate>

@end
