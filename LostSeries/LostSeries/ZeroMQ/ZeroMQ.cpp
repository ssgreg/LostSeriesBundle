//
//  ZeroMQ.cpp
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#include "ZeroMQ.h"


std::deque<ZmqMessagePtr> ZmqRecieveMultipartMessage(ZmqSocketPtr socket)
{
  std::deque<ZmqMessagePtr> result;
  while (true)
  {
    ZmqMessagePtr frame(new zmq::message_t());
    socket->recv(&*frame);
    result.push_back(frame);
    if (!frame->more())
    {
      break;
    }
  }
  return result;
}

void ZmqSendMultipartMessage(ZmqSocketPtr socket, std::deque<ZmqMessagePtr> messages)
{
  while (!messages.empty())
  {
    ZmqMessagePtr part = messages.front();
    messages.pop_front();
    socket->send(*part, messages.empty() ? 0 : ZMQ_SNDMORE);
  }
}

ZmqMessagePtr ZmqZeroFrame()
{
  return ZmqMessagePtr(new zmq::message_t);
}

zmq::context_t& ZmqGlobalContext()
{
  static zmq::context_t theOnlyOneContext;
  return theOnlyOneContext;
}
