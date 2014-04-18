//
//  JetBadge.m
//  Jet
//
//  Created by Grigory Zubankov on 17/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Jet
#import "JetBadge.h"


//
// JetBadge
//

@implementation JetBadge
{
  NSString* theTextBadge;
  UIColor* theColorText;
  UIColor* theColorInset;
}

+ (JetBadge*) customBadgeWithString:(NSString*)badgeString
{
	return [[self alloc] initWithString:badgeString];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
  if (!(self = [super initWithCoder:aDecoder]))
  {
    return nil;
  }
  [self configure];
	return self;
}

- (id) initWithFrame:(CGRect)frame
{
  if (!(self = [super initWithFrame:frame]))
  {
    return nil;
  }
  [self configure];
	return self;
}

- (id) initWithString:(NSString*)badgeString
{
  if (!(self = [super initWithFrame:CGRectNull]))
  {
    return nil;
  }
  [self configure];
  self.textBadge = badgeString;
	return self;
}

- (void) configure
{
  self.backgroundColor = [UIColor clearColor];
  //
	theColorText = [UIColor whiteColor];
	theColorInset = [UIColor colorWithRed:(60/255.0) green:(171/255.0) blue:(218/255.0) alpha:1.];
}

- (void) setTextBadge:(NSString*)badgeText
{
  theTextBadge = badgeText;
  [self setNeedsDisplay];
}

- (NSString*) textBadge
{
  return theTextBadge;
}


- (CGRect) frameBadge
{
  CGRect rect = CGRectMake(0, 0, 22, 22);
  //
  if ([self.textBadge length] > 1)
  {
    NSDictionary* attributes = @{ NSFontAttributeName:[self fontBadgeText] };
    CGSize size = [self.textBadge sizeWithAttributes:attributes];
    //
    rect.size.width = size.width + rect.size.width / 2;
  }
  //
  return CGRectMake(self.frame.size.width - rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
}

- (void) drawRoundedRectWithContext:(CGContextRef)context withRect:(CGRect)rect
{
	CGContextSaveGState(context);
  {
    CGFloat radius = rect.size.height / 2;
    //
    CGContextBeginPath(context);
    {
      CGContextSetFillColorWithColor(context, [theColorInset CGColor]);
      CGContextSetAllowsAntialiasing(context, YES);
      CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, radius, M_PI + M_PI_2, 0, 0);
      CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.size.height - radius, radius, 0, M_PI_2, 0);
      CGContextAddArc(context, rect.origin.x + radius, rect.size.height - radius, radius, M_PI_2, M_PI, 0);
      CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius, M_PI, M_PI + M_PI_2, 0);
    }
    CGContextFillPath(context);
  }
	CGContextRestoreGState(context);
}

- (void) drawBadgeTextWithContext:(CGContextRef)context withRect:(CGRect)rect
{
  if ([self.textBadge length])
  {
    NSDictionary* attributes = @{ NSFontAttributeName:[self fontBadgeText], NSForegroundColorAttributeName:theColorText };
		CGSize size = [self.textBadge sizeWithAttributes:attributes];
    CGPoint point = CGPointMake((rect.size.width - size.width) / 2 + rect.origin.x, (rect.size.height - size.height) / 2);
    //
		[self.textBadge drawAtPoint:point withAttributes:attributes];
	}
}

- (UIFont*) fontBadgeText
{
  CGFloat sizeFont = 13.5;
  //
  if ([self.textBadge length] == 1)
  {
    sizeFont += sizeFont * .2;
  }
  return [UIFont systemFontOfSize:sizeFont];
}

- (void) drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[self drawRoundedRectWithContext:context withRect:[self frameBadge]];
  [self drawBadgeTextWithContext:context withRect:[self frameBadge]];
}

@end
