//
//  LSShowsFollowingController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 16/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSShowsFollowingController.h"


//
// LSShowsFollowingController
//

@implementation LSShowsFollowingController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] postNotificationName:LSShowsFollowingControllerDidLoadNotification object:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

@end


//
// Notifications
//

NSString* LSShowsFollowingControllerDidLoadNotification = @"LSShowsFollowingControllerDidLoadNotification";
