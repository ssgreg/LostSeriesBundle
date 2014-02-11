//
//  main.m
//  LostSeries
//
//  Created by Grigory Zubankov on 09/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSAppDelegate.h"
#import "Logic/LSApplication.h"

int main(int argc, char * argv[])
{
  @autoreleasepool
  {
    // hold single instance of application
    LSApplication* singleInstance = [LSApplication singleInstance];
    #pragma unused(singleInstance)
    //
    return UIApplicationMain(argc, argv, nil, NSStringFromClass([LSAppDelegate class]));
  }
}
