//
//  ZeroMQ.h
//  LostSeries
//
//  Created by Grigory Zubankov on 21/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#pragma once

// zeromq
#include <zmq.hpp>
// std
#include <memory>
#include <deque>


// types
typedef std::shared_ptr<zmq::context_t> ZmqContextPtr;
typedef std::shared_ptr<zmq::socket_t> ZmqSocketPtr;
typedef std::shared_ptr<zmq::message_t> ZmqMessagePtr;


std::deque<ZmqMessagePtr> ZmqRecieveMultipartMessage(ZmqSocketPtr socket);
void ZmqSendMultipartMessage(ZmqSocketPtr socket, std::deque<ZmqMessagePtr> messages);
ZmqMessagePtr ZmqZeroFrame();

zmq::context_t& ZmqGlobalContext();