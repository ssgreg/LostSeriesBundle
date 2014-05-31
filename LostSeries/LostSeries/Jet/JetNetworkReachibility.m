//
//  JetNetworkReachibility.m
//  LostSeries
//
//  Created by 0xGreg on 26/05/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "JetNetworkReachibility.h"
#import <SystemConfiguration/SystemConfiguration.h>
//
#include <netdb.h>
#include <arpa/inet.h>


static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target, flags)
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
//    NSCAssert([(__bridge NSObject*) info isKindOfClass: [LSCachingServer class]], @"info was wrong class in ReachabilityCallback");
//// 
//    LSCachingServer* noteObject = (__bridge LSCachingServer *)info;
//  [noteObject DoIt];
  
//    // Post a notification to notify the client that the network reachability changed.
//    [[NSNotificationCenter defaultCenter] postNotificationName: kReachabilityChangedNotification object: noteObject];
      [[NSNotificationCenter defaultCenter] postNotificationName:JetNetworkReachibilityDidChange object:nil];

}



@implementation JetNetworkReachibility

- (void) do1
{
   
//    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "server.lostseriesapp.com");
	struct sockaddr_in localWifiAddress;
	bzero(&localWifiAddress, sizeof(localWifiAddress));
	localWifiAddress.sin_len = sizeof(localWifiAddress);
	localWifiAddress.sin_family = AF_INET;

	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0.
	localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);

  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&localWifiAddress);



  //
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
// 
    if (SCNetworkReachabilitySetCallback(reachability, ReachabilityCallback, &context))
    {
        if (SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
          BOOL  returnValue = YES;
        }
    }
  
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;

    SCNetworkReachabilityRef reachability1 = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);



  //
    SCNetworkReachabilityContext context1 = {0, (__bridge void *)(self), NULL, NULL, NULL};
// 
    if (SCNetworkReachabilitySetCallback(reachability1, ReachabilityCallback, &context1))
    {
        if (SCNetworkReachabilityScheduleWithRunLoop(reachability1, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
          BOOL  returnValue = YES;
        }
    }

  
  //  struct hostent *hostentry;
//hostentry = gethostbyname("server.lostseriesapp.com");
//char * ipbuf;
//ipbuf = inet_ntoa(*((struct in_addr *)hostentry->h_addr_list[0]));
  

  
 
}

+ (JetNetworkReachibility*) start
{
  JetNetworkReachibility* network = [[JetNetworkReachibility alloc] init];
  [network do1];
  return network;
}

@end


//
// Notifications
//

NSString* JetNetworkReachibilityDidChange = @"JetNetworkReachibilityDidChange";
