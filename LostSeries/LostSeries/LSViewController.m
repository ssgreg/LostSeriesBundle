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
#include "LostSeriesProtocol.pb.h"


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



@interface LSServerRoutine : NSObject

// init
- (id) init;

// factory methods
+ (LSServerRoutine*) serverRoutine;

// requests
- (NSArray*) askShowInfoArray;
- (NSData*) askArtworkByOriginalTitle:(NSString*)originalTitle snapshot:(NSString*)snapshot;

@end


@interface LSServerRoutine ()
{
@private
  std::shared_ptr<LS::ServerRoutine> theServerRoutine;
}
@end


@implementation LSServerRoutine

- (id) init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  theServerRoutine = LS::MakeServerRoutine();
  return self;
}

+ (LSServerRoutine*) serverRoutine
{
  return [[LSServerRoutine alloc] init];
}

- (NSArray*) askShowInfoArray
{
  LS::SeriesRequest seriesRequest;
  //
  LS::Message question;
  *question.mutable_seriesrequest() = seriesRequest;
  LS::Message answer = theServerRoutine->AskServer(question);
  //
  if (!answer.has_seriesresponse())
  {
    return nil;
  }
  NSMutableArray* shows = [NSMutableArray array];
  int showsSize = answer.seriesresponse().shows_size();
  for (int i = 0; i < showsSize; ++i)
  {
    LS::SeriesResponse_TVShow show = answer.seriesresponse().shows(i);
    LSShowInfo* showInfo = [LSShowInfo showInfo];
    showInfo.title = [NSString stringWithUTF8String: show.title().c_str()];
    showInfo.originalTitle = [NSString stringWithUTF8String: show.originaltitle().c_str()];
    showInfo.seasonNumber = show.seasonnumber();
    showInfo.snapshot = [NSString stringWithCString: show.snapshot().c_str() encoding:NSASCIIStringEncoding];
    //
    [shows addObject:showInfo];
  }
  return shows;
}

- (NSData*) askArtworkByOriginalTitle:(NSString*)originalTitle snapshot:(NSString*)snapshot
{
  LS::ArtworkRequest artworkRequest;
  artworkRequest.set_originaltitle([originalTitle UTF8String]);
  artworkRequest.set_snapshot([snapshot cStringUsingEncoding:NSASCIIStringEncoding]);
  //
  LS::Message question;
  *question.mutable_artworkrequest() = artworkRequest;
  LS::Message answer = theServerRoutine->AskServer(question);
  if (!answer.has_artworkresponse())
  {
    return nil;
  }
  std::string const& artwork = answer.artworkresponse().artwork();
  if (artwork.empty())
  {
    return nil;
  }
  return [NSData dataWithBytes:artwork.c_str() length:artwork.size()];
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
  NSArray* shows = [theServerRoutine askShowInfoArray];
  
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                     NSData* artworkData = [theServerRoutine askArtworkByOriginalTitle:cellModel.showInfo.originalTitle snapshot:cellModel.showInfo.snapshot];
                     cellModel.artwork = [UIImage imageWithData:artworkData];
                     NSLog(@"req=%ld", indexPath.row);
                     dispatch_async(dispatch_get_main_queue(),
                                    ^{
                                      LSShowAlbumCell* blockCell = (LSShowAlbumCell*)[collectionView cellForItemAtIndexPath: indexPath];
                                      blockCell.image.image = cellModel.artwork;
                                      [blockCell setNeedsLayout];
                                    });
                   });
  }
  return cell;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
////  static NSString *cellIdentifier = @"venue";
////  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
////
////  if (!cell) {
////    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
////  }
//
//  Venue *venue = ((Venue * )self.venues[indexPath.row]);
//  if (venue.userImage) {
//    cell.imageView.image = venue.image;
//  } else {
//    // set default user image while image is being downloaded
//    cell.imageView.image = [UIImage imageNamed:@"batman.png"];
//
//    // download the image asynchronously
//    [self downloadImageWithURL:venue.url completionBlock:^(BOOL succeeded, UIImage *image) {
//      if (succeeded) {
//        // change the image in the cell
//        cell.imageView.image = image;
//
//        // cache the image for use later (when scrolling up)
//        venue.image = image;
//      }
//    }];
//  }
//}
//
//- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
//{
//  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//  [NSURLConnection sendAsynchronousRequest:request
//                                     queue:[NSOperationQueue mainQueue]
//                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
//                           if ( !error )
//                           {
//                             UIImage *image = [[UIImage alloc] initWithData:data];
//                             completionBlock(YES,image);
//                           } else{
//                             completionBlock(NO,nil);
//                           }
//                         }];
//}

//- (PSTCollectionViewCell *)collectionView:(PSTCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//  NSURL *url = [NSURL URLWithString:[allImage objectAtIndex:indexPath]];
//
//  [self downloadImageWithURL:url completionBlock:^(BOOL succeeded, NSData *data) {
//    if (succeeded) {
//      cell.grid_image.image = [[UIImage alloc] initWithData:data];
//    }
//  }];
//}
//
//- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, NSData *data))completionBlock
//{
//  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//  [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
//    if (!error) {
//      completionBlock(YES, data);
//    } else {
//      completionBlock(NO, nil);
//    }
//  }];


@end
