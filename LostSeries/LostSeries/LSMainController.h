//
//  LSMainController.h
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
  LSRouterNavigationWayShows,
  LSRouterNavigationWayShowsFollowing,
} LSRouterNavigationWay;

//
// LSViewRouterNavigation
//

@protocol LSViewRouterNavigation <NSObject>
@property (readonly) LSRouterNavigationWay routerNavigationWay;
@end


//
// LSMainController
//

@interface LSMainController : UITabBarController <UITabBarControllerDelegate, LSViewRouterNavigation>
@end
