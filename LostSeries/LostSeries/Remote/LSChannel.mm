//
//  LSChannel.m
//  LostSeries
//
//  Created by Grigory Zubankov on 17/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSChannel.h"


//
// LSChannel
//

@interface LSChannel ()
{
@private
  void (^theSendHandler)(LS::Message const&, id);
}

@end

@implementation LSChannel

+ (LSChannel*) serverChannelWithSendHandler:(void (^)(LS::Message const&, id))handler
{
  return [[LSChannel alloc] initWithSendHandler:handler];
}

- (id) initWithSendHandler:(void (^)(LS::Message const&, id))handler
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theSendHandler = handler;
  return self;
}

- (void) send:(LS::Message const&)request completionHandler:(void (^)(LS::Message const& reply))handler
{
  theSendHandler(request, handler);
}

@end
