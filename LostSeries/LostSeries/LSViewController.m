//
//  LSViewController.m
//  LostSeries
//
//  Created by Grigory Zubankov on 09/01/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

#import "LSViewController.h"
//
#include <zmq.hpp>
#include <memory>
#include <LostSeriesProtocol.pb.h>


namespace LS
{
  
  //
  // ServerRoutine
  //
  class ServerRoutine
  {
  public:
    ServerRoutine(std::shared_ptr<zmq::socket_t> socket, std::shared_ptr<zmq::context_t> context);
    //
    Message AskServer(Message question);
    
    ~ServerRoutine()
    {
    }
    
  private:
    // strict order! The Context have to be destoyed after the Socket.
    std::shared_ptr<zmq::context_t> TheContext;
    std::shared_ptr<zmq::socket_t> TheSocket;
    //
    dispatch_queue_t theQueue;
  };
  
  
  //
  // ServerRoutine
  //
  
  ServerRoutine::ServerRoutine(std::shared_ptr<zmq::socket_t> socket, std::shared_ptr<zmq::context_t> context)
  : TheSocket(socket), TheContext(context)
  {
    theQueue = dispatch_queue_create("server_routine.locking.queue", NULL);
  }
  
  Message ServerRoutine::AskServer(Message question)
  {
    __block Message answer;
    dispatch_sync(theQueue,
                  ^{
                    // send question
                    zmq::message_t zmqRequest(question.ByteSize());
                    question.SerializeToArray(zmqRequest.data(), (int)zmqRequest.size());
                    TheSocket->send(zmqRequest, 0);
                    // recieve answer
                    zmq::message_t zmqResponse;
                    TheSocket->recv(&zmqResponse);
                    answer.ParseFromArray(zmqResponse.data(), (int)zmqResponse.size());
                    [NSThread sleepForTimeInterval: 1];
                  });
    return answer;
  }
  
  
  //
  // ServerRoutine factory
  //
  
  std::shared_ptr<ServerRoutine> MakeServerRoutine()
  {
    std::shared_ptr<zmq::context_t> context(new zmq::context_t);
    std::shared_ptr<zmq::socket_t> socket(new zmq::socket_t(*context, ZMQ_REQ));
    socket->connect("tcp://10.0.1.10:8500");
    //
    return std::shared_ptr<ServerRoutine>(new ServerRoutine(socket, context));
  }
  
  
} // namespace LS


@interface LSViewController ()

@end

@implementation LSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
