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
#include <deque>

#include <Protobuf.Generated/LostSeriesProtocol.h>


typedef std::shared_ptr<zmq::context_t> ZmqContextPtr;
typedef std::shared_ptr<zmq::socket_t> ZmqSocketPtr;
typedef std::shared_ptr<zmq::message_t> ZmqMessagePtr;


//
// LSShowInfo
//

@interface LSShowInfo : NSObject

@property NSString* title;
@property NSString* originalTitle;
@property NSInteger seasonNumber;
@property NSString* snapshot;

- (id) initWithTitle:(NSString*)title
       originalTitle:(NSString*)originalTitle
        seasonNumber:(NSInteger)seasonNumber
            snapshot:(NSString*)snapshot;

+ (LSShowInfo*) showInfo;

+ (LSShowInfo*) showInfoWithTitle:(NSString*)title
                    originalTitle:(NSString*)originalTitle
                     seasonNumber:(NSInteger)seasonNumber
                         snapshot:(NSString*)snapshot;

@end


@implementation LSShowInfo

@synthesize title = theTitle;
@synthesize originalTitle = theOriginalTitle;
@synthesize seasonNumber = theSeasonNumber;
@synthesize snapshot = theSnapshot;

- (id) initWithTitle:(NSString*)title
       originalTitle:(NSString*)originalTitle
        seasonNumber:(NSInteger)seasonNumber
            snapshot:(NSString*)snapshot
{
  if (!(self = [super init]))
  {
    return nil;
  }
  [self setTitle:title];
  [self setOriginalTitle:originalTitle];
  [self setSeasonNumber:seasonNumber];
  [self setSnapshot:snapshot];
  return self;
}

+ (LSShowInfo*)showInfo
{
  return [[LSShowInfo alloc] init];
}

+ (LSShowInfo*)showInfoWithTitle:(NSString*)title
                   originalTitle:(NSString*)originalTitle
                    seasonNumber:(NSInteger)seasonNumber
                        snapshot:(NSString*)snapshot
{
  return [[LSShowInfo alloc] initWithTitle:title originalTitle:originalTitle seasonNumber:seasonNumber snapshot:snapshot];
}

@end


//
// LSServerChannel
//

@interface LSServerChannel : NSObject

+ (LSServerChannel*) serverChannelWithAskHandler:(void (^)(LS::Message const&, id))handler;

- (id) initWithAskHandler:(void (^)(LS::Message const&, id))handler;

// interface
- (void) askServer:(LS::Message const&)question callback:(void (^)(LS::Message const& answer))callback;

@end

@interface LSServerChannel ()
{
@private
  void (^theAskHandler)(LS::Message const&, id);
}

@end

@implementation LSServerChannel

+ (LSServerChannel*) serverChannelWithAskHandler:(void (^)(LS::Message const&, id))handler
{
  return [[LSServerChannel alloc] initWithAskHandler:handler];
}

- (id) initWithAskHandler:(void (^)(LS::Message const&, id))handler
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theAskHandler = handler;
  return self;
}

- (void) askServer:(LS::Message const&)question callback:(void (^)(LS::Message const& answer))callback
{
  theAskHandler(question, callback);
}

@end


//
// LSServerRoutine
//

@interface LSServerRoutine : NSObject

+ (LSServerRoutine*) serverRoutine;

- (id) init;
- (LSServerChannel*) createPriorityServerChannel;
- (LSServerChannel*) createBackgroundServerChannel;

@end

@interface LSServerRoutine ()
{
@private
  NSMutableDictionary* theHandlers;
  //
  dispatch_queue_t thePollQueue;
  int64_t theMessageID;
  //
  ZmqContextPtr theContext;
  // priority sockets
  ZmqSocketPtr thePriorityBackend;
  ZmqSocketPtr thePriorityFrontend;
  ZmqSocketPtr thePriorityChannel;
  // background sockets
  ZmqSocketPtr theBackgroundBackend;
  ZmqSocketPtr theBackgroundFrontend;
  ZmqSocketPtr theBackgroundChannel;
}

- (void) startPollQueue;
- (LSServerChannel*) createServerChannel:(ZmqSocketPtr)socket;
- (void) askServer:(ZmqSocketPtr)socket question:(LS::Message)question callback:(id)block;
- (void) dispatchMessageFrom:(ZmqSocketPtr)socket;
- (void) forwardMessageFrom:(ZmqSocketPtr)socketFrom to:(ZmqSocketPtr)socketTo;
- (std::deque<ZmqMessagePtr>) recieveMultipartMessage:(ZmqSocketPtr)socket;

@end

@implementation LSServerRoutine

+ (LSServerRoutine*) serverRoutine
{
  return [[LSServerRoutine alloc] init];
}

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  static char const* backendAddres = "tcp://localhost:8500";
  static char const* frontendPriorityAddres = "inproc://server_routine.priority_request_puller";
  static char const* frontendBackgroundAddres = "inproc://server_routine.background_request_puller";
  //
  theHandlers = [NSMutableDictionary dictionary];
  thePollQueue = dispatch_queue_create("server_dispatcher.proxy.queue", NULL);
  theMessageID = 0;
  //
  theContext = ZmqContextPtr(new zmq::context_t);
  //
  thePriorityBackend = ZmqSocketPtr(new zmq::socket_t(*theContext, ZMQ_DEALER));
  thePriorityBackend->connect(backendAddres);
  thePriorityFrontend = ZmqSocketPtr(new zmq::socket_t(*theContext, ZMQ_PULL));
  thePriorityFrontend->bind(frontendPriorityAddres);
  thePriorityChannel = ZmqSocketPtr(new zmq::socket_t(*theContext, ZMQ_PUSH));
  thePriorityChannel->connect(frontendPriorityAddres);
  //
  theBackgroundBackend = ZmqSocketPtr(new zmq::socket_t(*theContext, ZMQ_DEALER));
  theBackgroundBackend->connect(backendAddres);
  theBackgroundFrontend = ZmqSocketPtr(new zmq::socket_t(*theContext, ZMQ_PULL));
  theBackgroundFrontend->bind(frontendBackgroundAddres);
  theBackgroundChannel = ZmqSocketPtr(new zmq::socket_t(*theContext, ZMQ_PUSH));
  theBackgroundChannel->connect(frontendBackgroundAddres);
  //
  [self startPollQueue];
  return self;
}

- (LSServerChannel*) createPriorityServerChannel
{
  return [self createServerChannel:thePriorityChannel];
}

- (LSServerChannel*) createBackgroundServerChannel
{
  return [self createServerChannel:theBackgroundChannel];
}

- (void) startPollQueue
{
  dispatch_async(thePollQueue,
  ^{
    while (TRUE)
    {
      zmq_pollitem_t items [] =
      {
        { *thePriorityBackend, 0, ZMQ_POLLIN, 0 },
        { *thePriorityFrontend, 0, ZMQ_POLLIN, 0 },
        { *theBackgroundBackend, 0, ZMQ_POLLIN, 0 },
        { *theBackgroundFrontend, 0, ZMQ_POLLIN, 0 },
      };
      if (zmq::poll(items, sizeof(items) / sizeof(zmq_pollitem_t)) <= 0)
      {
        continue;
      }
      if (items[0].revents & ZMQ_POLLIN)
      {
        [self dispatchMessageFrom:thePriorityBackend];
      }
      else if (items[1].revents & ZMQ_POLLIN)
      {
        [self forwardMessageFrom:thePriorityFrontend to:thePriorityBackend];
      }
      if (items[2].revents & ZMQ_POLLIN)
      {
        [self dispatchMessageFrom:theBackgroundBackend];
      }
      else if (items[3].revents & ZMQ_POLLIN)
      {
        [self forwardMessageFrom:theBackgroundFrontend to:theBackgroundBackend];
      }
    }
  });
}

- (LSServerChannel*) createServerChannel:(ZmqSocketPtr)socket
{
  __weak typeof(self) weakSelf = self;
  void (^askHandler)(LS::Message const&, id) = ^(LS::Message const& message, id callback)
  {
    [weakSelf askServer:socket question:message callback:callback];
  };
  return [LSServerChannel serverChannelWithAskHandler: askHandler];
}

- (void) askServer:(ZmqSocketPtr)socket question:(LS::Message)question callback:(id)block
{
  ++theMessageID;
  [theHandlers setObject:block forKey: [NSNumber numberWithLongLong: theMessageID ]];
  question.set_messageid(theMessageID);
  //  send question
  zmq::message_t zmqRequest(question.ByteSize());
  question.SerializeToArray(zmqRequest.data(), (int)zmqRequest.size());
  //
  socket->send(zmqRequest, 0);
}

- (void) dispatchMessageFrom:(ZmqSocketPtr)socket
{
  std::deque<ZmqMessagePtr> messages = [self recieveMultipartMessage:socket];
  if (messages.front()->size() == 0)
  {
    messages.pop_front();
    if (messages.size() == 1)
    {
      LS::Message answer;
      answer.ParseFromArray(messages.front()->data(), (int)messages.front()->size());
      //
      NSNumber* key = [NSNumber numberWithLongLong: answer.messageid()];
      id callback = [theHandlers objectForKey: key];
      [theHandlers removeObjectForKey:key];
      if (callback)
      {
        ((void (^)(LS::Message const&))(callback))(answer);
      }
    }
  }
}

- (void) forwardMessageFrom:(ZmqSocketPtr)socketFrom to:(ZmqSocketPtr)socketTo
{
  std::deque<ZmqMessagePtr> messages = [self recieveMultipartMessage:socketFrom];
  if (messages.size() == 1)
  {
    socketTo->send(0, 0, ZMQ_SNDMORE);
    socketTo->send(*messages.front(), 0);
  }
}

- (std::deque<ZmqMessagePtr>) recieveMultipartMessage:(ZmqSocketPtr)socket
{
  std::deque<ZmqMessagePtr> result;
  while (true)
  {
    ZmqMessagePtr frame(new zmq::message_t());
    socket->recv(&*frame);
    result.push_back(frame);
    if (!frame->more())
      break;
  }
  return result;
}

@end


// LSServerProtocol
@interface LSServerProtocol : NSObject

+ (LSServerProtocol*) serverProtocolWithChannel:(LSServerChannel*)channel;

- (id) initWithChannel:(LSServerChannel*)channel;

// requests
- (void) askServer:(LS::Message const&)question callback:(id)callback;
- (void) askShowInfoArray:(void (^)(NSArray*))callback;
- (void) askArtwork:(LSShowInfo*)showInfo callback:(void (^)(NSData*))callback;

@end


@interface LSServerProtocol ()
{
@private
  LSServerChannel* theChannel;
}

// dispatch
- (void) dispatchMessage:(LS::Message const&)message callback:(id)callback;
- (void) handleSeriesResponse:(LS::SeriesResponse const&)response callback:(void (^)(NSArray*))callback;
- (void) handleArtworkResponse:(LS::ArtworkResponse const&)response callback:(void (^)(NSData*))callback;

@end

@implementation LSServerProtocol


+ (LSServerProtocol*) serverProtocolWithChannel:(LSServerChannel*)channel;
{
  return [[LSServerProtocol alloc] initWithChannel:channel];
}

- (id) initWithChannel:(LSServerChannel*)channel
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theChannel = channel;
  return self;
}

- (void) askServer:(LS::Message const&)question callback:(id)callback
{
  __weak typeof(self) weakSelf = self;
  void (^dispatchHandler)(LS::Message const&) = ^(LS::Message const& message)
  {
    [weakSelf dispatchMessage:message callback:callback];
  };
  [theChannel askServer:question callback:dispatchHandler];
}

- (void) askShowInfoArray:(void (^)(NSArray*))callback
{
  LS::SeriesRequest seriesRequest;
  //
  LS::Message question;
  *question.mutable_seriesrequest() = seriesRequest;
  //
  [self askServer:question callback:callback];
}

- (void) askArtwork:(LSShowInfo*)showInfo callback:(void (^)(NSData*))callback
{
  LS::ArtworkRequest artworkRequest;
  artworkRequest.set_originaltitle([showInfo.originalTitle UTF8String]);
  artworkRequest.set_snapshot([showInfo.snapshot cStringUsingEncoding:NSASCIIStringEncoding]);
  //
  LS::Message question;
  *question.mutable_artworkrequest() = artworkRequest;
  //
  [self askServer:question callback:callback];
}

- (void) dispatchMessage:(LS::Message const&)message callback:(id)callback
{
  if (message.has_seriesresponse())
  {
    [self handleSeriesResponse:message.seriesresponse() callback:callback];
  }
  else if (message.has_artworkresponse())
  {
    [self handleArtworkResponse:message.artworkresponse() callback:callback];
  }
}

- (void) handleSeriesResponse:(LS::SeriesResponse const&)answer callback:(void (^)(NSArray*))callback
{
  NSMutableArray* shows = [NSMutableArray array];
  int showsSize = answer.shows_size();
  for (int i = 0; i < showsSize; ++i)
  {
    LS::SeriesResponse_TVShow show = answer.shows(i);
    LSShowInfo* showInfo = [LSShowInfo showInfo];
    showInfo.title = [NSString stringWithUTF8String: show.title().c_str()];
    showInfo.originalTitle = [NSString stringWithUTF8String: show.originaltitle().c_str()];
    showInfo.seasonNumber = show.seasonnumber();
    showInfo.snapshot = [NSString stringWithCString: show.snapshot().c_str() encoding:NSASCIIStringEncoding];
    //
    [shows addObject:showInfo];
  }
  callback(shows);
}

- (void) handleArtworkResponse:(LS::ArtworkResponse const&)answer callback:(void (^)(NSData*))callback
{
  std::string const& artwork = answer.artwork();
  if (!artwork.empty())
  {
    callback([NSData dataWithBytes:artwork.c_str() length:artwork.size()]);
  }
}

@end


@interface LSShowAlbumCellModel : NSObject

@property LSShowInfo* showInfo;
@property UIImage* artwork;

@end


@implementation LSShowAlbumCellModel

@synthesize showInfo = theShowInfo;
@synthesize artwork = theArtwork;

+ (LSShowAlbumCellModel*)showAlbumCellModel
{
  return [[LSShowAlbumCellModel alloc] init];
}

@end



@interface LSShowAlbumCell : UICollectionViewCell

@property IBOutlet UIImageView* image;
@property IBOutlet UILabel* detail;

@end

@implementation LSShowAlbumCell

@synthesize image = theImage;
@synthesize detail = theDetail;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
  }
  return self;
}

@end



//
// LSViewController
//

@interface LSViewController ()
{
  NSMutableArray* theItems;
  LSServerRoutine* theServerRoutine;
  LSServerProtocol* theServerProtocol;
  IBOutlet UICollectionView* theCollectionView;
}
@end

@implementation LSViewController

//- (void)image:(UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
//  NSLog(@"SAVE IMAGE COMPLETE");
//  if(error != nil) {
//    NSLog(@"ERROR SAVING:%@",[error localizedDescription]);
//  }
//}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  theServerRoutine = [LSServerRoutine serverRoutine];
  theServerProtocol = [LSServerProtocol serverProtocolWithChannel:[theServerRoutine createPriorityServerChannel]];
  //
  [theServerProtocol askShowInfoArray: ^(NSArray* shows)
  {
    dispatch_async(dispatch_get_main_queue(),
    ^{
      theItems = [NSMutableArray array];
      for (int i = 1; i < 40; ++i)
      {
        for (id show in shows)
        {
          LSShowAlbumCellModel* cellModel = [LSShowAlbumCellModel showAlbumCellModel];
          cellModel.showInfo = show;
          [theItems addObject: cellModel];
        }
      }
      [theCollectionView reloadData];
    });
  }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [theItems count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  LSShowAlbumCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"theCell" forIndexPath:indexPath];
  //
  LSShowAlbumCellModel* cellModel = [theItems objectAtIndex: indexPath.row];
  cell.detail.text = cellModel.showInfo.title;
  cell.image.image = cellModel.artwork;
  NSLog(@"settttt=%ld", indexPath.row);
  
  if (!cellModel.artwork)
  {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
//                   ^{
//                     NSData* artworkData = [theServerRoutine askArtworkByOriginalTitle:cellModel.showInfo.originalTitle snapshot:cellModel.showInfo.snapshot];
//                     cellModel.artwork = [UIImage imageWithData:artworkData];
//                     NSLog(@"req=%ld", indexPath.row);
//                     dispatch_async(dispatch_get_main_queue(),
//                                    ^{
//                                      LSShowAlbumCell* blockCell = (LSShowAlbumCell*)[collectionView cellForItemAtIndexPath: indexPath];
//                                      blockCell.image.image = cellModel.artwork;
//                                      [blockCell setNeedsLayout];
//                                    });
//                   });
  }
  return cell;
}


@end
