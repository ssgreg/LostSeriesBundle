//
//  UIStatusBarView.m
//  UIComponents
//
//  Created by Grigory Zubankov on 12/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "UIStatusBarView.h"


//
// UIStatusBarView
//

@implementation UIStatusBarView
{
  UILabel* theLabel;
}

- (id)initWithFrame:(CGRect)frame
{
  if (!(self = [super initWithFrame:frame]))
  {
    return nil;
  }
  theLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  theLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
  theLabel.adjustsFontSizeToFitWidth = YES;
  //
  [self addSubview: theLabel];
  [self setBackgroundColor:[UIColor colorWithRed:(65/255.0) green:(95/255.0) blue:(127/255.0) alpha:1.f]];
  theLabel.textColor = [UIColor whiteColor];
  [self setText:nil];
  //
  return self;
}


- (void) setText:(NSString*)text
{
  // label
  theLabel.text = text;
  [theLabel sizeToFit];
  theLabel.center = self.center;
}

@end
