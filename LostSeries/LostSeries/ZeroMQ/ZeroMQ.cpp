//
//  ZeroMQ.cpp
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#include "ZeroMQ.h"


ZmqMessagePtr ZmqCopyFrame(ZmqMessagePtr frame)
{
  ZmqMessagePtr frameCopy(new zmq::message_t);
  frameCopy->copy(&*frame);
  return frameCopy;
}

std::deque<ZmqMessagePtr> ZmqCopyMultipartMessage(std::deque<ZmqMessagePtr> messages)
{
  std::deque<ZmqMessagePtr> result;
  while (!messages.empty())
  {
    ZmqMessagePtr part = messages.front();
    messages.pop_front();
    result.push_back(ZmqCopyFrame(part));
  }
  return result;
}

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
//
//- (ZmqMessagePtr) copyMultipartRequest:(std::deque<ZmqMessagePtr> const&)multipartRequest
//{
//  ZmqMessagePtr result(new zmq::message_t);
//  result->copy(&*request);
//  return result;
//}


ZmqMessagePtr ZmqZeroFrame()
{
  return ZmqMessagePtr(new zmq::message_t);
}

zmq::context_t& ZmqGlobalContext()
{
  static zmq::context_t theOnlyOneContext;
  return theOnlyOneContext;
}

ZmqMessagePtr ZmqMakeMessage(LSMessagePtr request)
{
  ZmqMessagePtr requestBody = ZmqMessagePtr(new zmq::message_t(request->ByteSize()));
  request->SerializeToArray(requestBody->data(), (int)requestBody->size());
  return requestBody;
}

LSMessagePtr ZmqParseMessage(ZmqMessagePtr replyFrame)
{
  LSMessagePtr reply(new LS::Message);
  reply->ParseFromArray(replyFrame->data(), (int)replyFrame->size());
  return reply;  
}

ZmqMessagePtr ZmqMakeHeaderMessage(int64_t messageID)
{
  LS::Header header;
  header.set_messageid(messageID);
  //
  ZmqMessagePtr zmqHeader = ZmqMessagePtr(new zmq::message_t(header.ByteSize()));
  header.SerializeToArray(zmqHeader->data(), (int)zmqHeader->size());
  return zmqHeader;
}

int64_t ZmqParseHeaderMessage(ZmqMessagePtr headerFrame)
{
  LS::Header header;
  header.ParseFromArray(headerFrame->data(), (int)headerFrame->size());
  return header.messageid();
}
