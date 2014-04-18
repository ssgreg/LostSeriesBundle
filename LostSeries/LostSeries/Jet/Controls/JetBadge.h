//
//  JetBadge.h
//  Jet
//
//  Created by Grigory Zubankov on 17/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import <UIKit/UIKit.h>


//
// JetBadge
//

@interface JetBadge : UIView

#pragma mark - Factory Methods
+ (JetBadge*) customBadgeWithString:(NSString *)badgeText;

#pragma mark - Properties
@property NSString* textBadge;

@end