//
//  UILoadingView.m
//  UIComponents
//
//  Created by Grigory Zubankov on 07/02/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "UILoadingView.h"


//
// UILoadingView
//

@interface UILoadingView ()
{
  UILabel* theLabel;
  UIActivityIndicatorView* theActivityIndicator;
}
@end

@implementation UILoadingView

- (id)initWithFrame:(CGRect)frame
{
  if (!(self = [super initWithFrame:frame]))
  {
    return nil;
  }
  theLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  theActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [theActivityIndicator startAnimating];
  //
  [self addSubview: theLabel];
  [self addSubview: theActivityIndicator];
  [self setBackgroundColor:[UIColor whiteColor]];
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
  // activity indicator
  theActivityIndicator.frame = CGRectMake
  (
    theLabel.frame.origin.x - theActivityIndicator.frame.size.width - 5,
    theLabel.frame.origin.y,
    theActivityIndicator.frame.size.width,
    theActivityIndicator.frame.size.height
  );
}

@end
