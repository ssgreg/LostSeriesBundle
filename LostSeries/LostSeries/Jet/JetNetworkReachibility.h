//
//  JetNetworkReachibility.h
//  LostSeries
//
//  Created by 0xGreg on 26/05/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface JetNetworkReachibility : NSObject

+ (JetNetworkReachibility*) start;

@end


//
// Notifications
//

extern NSString* JetNetworkReachibilityDidChange;
