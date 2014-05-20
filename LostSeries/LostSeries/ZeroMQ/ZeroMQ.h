//
//  ZeroMQ.h
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#pragma once

// Protobuf
#include <Protobuf.Generated/LostSeriesProtocol.h>
// zeromq
#include <zmq.hpp>
// std
#include <memory>
#include <deque>
#include <list>


// types

typedef std::shared_ptr<zmq::context_t> ZmqContextPtr;
typedef std::shared_ptr<zmq::socket_t> ZmqSocketPtr;
typedef std::shared_ptr<zmq::message_t> ZmqMessagePtr;

typedef std::deque<ZmqMessagePtr> ZmqMultipartMessage;
typedef std::list<ZmqMultipartMessage> ZmqMultipartMessageList;

ZmqMessagePtr ZmqCopyFrame(ZmqMessagePtr);

std::deque<ZmqMessagePtr> ZmqCopyMultipartMessage(std::deque<ZmqMessagePtr> messages);
std::deque<ZmqMessagePtr> ZmqRecieveMultipartMessage(ZmqSocketPtr socket);
void ZmqSendMultipartMessage(ZmqSocketPtr socket, std::deque<ZmqMessagePtr> messages);
ZmqMessagePtr ZmqZeroFrame();

zmq::context_t& ZmqGlobalContext();


// protobuf

ZmqMessagePtr ZmqMakeMessage(LSMessagePtr request);
LSMessagePtr ZmqParseMessage(ZmqMessagePtr replyFrame);

ZmqMessagePtr ZmqMakeHeaderMessage(int64_t messageID);
int64_t ZmqParseHeaderMessage(ZmqMessagePtr headerFrame);
