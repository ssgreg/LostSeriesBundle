//
//  LSControllerShowDetails.m
//  LostSeries
//
//  Created by Grigory Zubankov on 25/03/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// LS
#import "LSControllerShowDetails.h"
#import "LSApplication.h"
// Jet
#import "Jet/JetGuard.h"
// WF
#import <WorkflowLink/WorkflowLink.h>
#import <WorkflowLink/WFLinkLockerDisposable.h>


//
// LSDataControllerShowDetails
//

@implementation LSDataControllerShowDetails
{
  LSModelBase* theModel;
  LSShowAlbumCellModel* theShow;
}

@synthesize show = theShow;
@synthesize episodesSorted;
@synthesize flagUnfollow;
@synthesize flagRemove;
@synthesize episodesToChange;

- initWithModel:(LSModelBase*)model show:(LSShowAlbumCellModel*)show
{
  if (!(self = [super init]))
  {
    return nil;
  }
  //
  theModel = model;
  theShow = show;
  //
  return self;
}

- (NSArray*) shows
{
  return theModel.shows;
}

- (LSAsyncBackendFacade*) backendFacade
{
  return theModel.backendFacade;
}

- (JetArrayPartial*) showsToChange
{
  return theModel.modelShowsLists.showsToChangeFollowing;
}

- (JetArrayPartial*) showsFollowing
{
  return theModel.showsFollowing;
}

- (void) modelDidChange
{
  [theModel modelDidChange];
}

- (BOOL) isShowFollowedByUser
{
  for (LSShowAlbumCellModel* show in self.showsFollowing)
  {
    if (show.showInfo.showID == self.show.showInfo.showID)
    {
      return YES;
    }
  }
  return NO;
}

- (NSInteger) indexOfShow
{
  for (NSInteger i = 0; i < self.shows.count; ++i)
  {
    LSShowAlbumCellModel* show = self.shows[i];
    if (show.showInfo.showID == self.show.showInfo.showID)
    {
      return i;
    }
  }
  return NSNotFound;
}

- (BOOL) isEpisodeUnwatchedWithNumber:(NSInteger)number
{
  if (!self.show.showInfo.episodesUnwatched)
  {
    return NO;
  }
  return [self.show.showInfo.episodesUnwatched indexOfObjectPassingTest:^BOOL(id object, NSUInteger index, BOOL* stop)
  {
    return ((LSEpisodeInfo*)object).number == number;
  }] != NSNotFound;
}

@end


//
// LSTableViewCellEpisodeInfo
//

@interface LSTableViewCellEpisodeInfo : UITableViewCell
@property IBOutlet UILabel* theEpisodeName;
@property IBOutlet UILabel* theEpisodeNameOriginal;
@property IBOutlet UILabel* theEpisodeDetails;
@property IBOutlet UIImageView* theImageMarkWatchingInfo;
@end
@implementation LSTableViewCellEpisodeInfo
@end


//
// LSWLinkShowDescription
//

@interface LSWLinkShowDescription : WFWorkflowLink
@end
@implementation LSWLinkShowDescription

SYNTHESIZE_WL_ACCESSORS_NEW(LSDataControllerShowDetails, LSViewShowDescription);

- (void) input
{
  [self.view setShowInfo:self.data.show.showInfo];
  [self output];
}

@end


//
// LSWLinkActionGetFullSizeArtwork
//

@interface LSWLinkActionGetFullSizeArtwork : WFWorkflowLink
@end
@implementation LSWLinkActionGetFullSizeArtwork
{
  JetGuard* theGuard;
}

SYNTHESIZE_WL_ACCESSORS_NEW(LSDataControllerShowDetails, LSViewActionGetFullSizeArtwork);

- (void) update
{
  theGuard = [JetGuard guard];
}

- (void) input
{
  if (theGuard.lock)
  {
    [self.data.backendFacade getArtworkByShowInfo:self.data.show.showInfo thumbnail:NO replyHandler:^(NSData* dataArtwork)
    {
      [self.view setImageArtwork: [UIImage imageWithData:dataArtwork]];
      [self output];
    }];
    // set thumbnail at first
    if (self.data.show.artwork)
    {
      [self.view setImageArtwork:self.data.show.artwork];
    }
  }
  [self output];
}

@end


//
// LSWLinkCollectionEpisodes
//

@interface LSWLinkCollectionEpisodes : WFWorkflowLink

- (BOOL) isUnwatchedItemAtIndex:(NSIndexPath*)indexPath;
- (LSEpisodeInfo*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) numberOfItems;

@end

@implementation LSWLinkCollectionEpisodes

SYNTHESIZE_WL_ACCESSORS_NEW(LSDataControllerShowDetails, LSViewCollectionEpisodes)

- (BOOL) isUnwatchedItemAtIndex:(NSIndexPath*)indexPath
{
  NSInteger numberEpisode = [self itemAtIndex:indexPath].number;
  return [self.data isEpisodeUnwatchedWithNumber:numberEpisode];
}

- (LSEpisodeInfo*) itemAtIndex:(NSIndexPath*)indexPath
{
  return self.data.episodesSorted[indexPath.row];
}

- (NSUInteger) numberOfItems
{
  return self.data.episodesSorted.count;
}

- (void) input
{
  self.data.episodesSorted = [self.data.show.showInfo.episodes sortedArrayUsingComparator:^NSComparisonResult(LSEpisodeInfo* left, LSEpisodeInfo* right)
  {
    return [[NSNumber numberWithInteger:right.number] compare:[NSNumber numberWithInteger:left.number]];
  }];
  [self.view reloadCollectionEpisodes];
  [self output];
}

@end


//
// LSWLinkEventChangeFollowing
//

@interface LSWLinkEventChangeFollowing : WFWorkflowLink
- (void) pulse;
@end
@implementation LSWLinkEventChangeFollowing

SYNTHESIZE_WL_ACCESSORS_NEW(LSDataControllerShowDetails, LSViewEventChangeFollowing);

- (void) input
{
  [self.view setIsFollowing:self.data.isShowFollowedByUser];
}

- (void) pulse
{
  [self output];
}

@end


//
// LSWLinkSetupActionChangeFollowing
//

@interface LSWLinkSetupActionChangeFollowing : WFWorkflowLink
@end
@implementation LSWLinkSetupActionChangeFollowing

SYNTHESIZE_WL_DATA_ACCESSOR_NEW(LSDataControllerShowDetails)

- (void) input
{
  self.data.flagUnfollow = !self.data.isShowFollowedByUser;
  [self.data.showsToChange removeAllObjectes];
  [self.data.showsToChange addObjectByIndexSource:self.data.indexOfShow];
  //
  [self output];
}

@end


//
// LSWLinkEventChangeUnwatchedEpisodes
//

@interface LSWLinkEventChangeUnwatchedEpisodes : WFWorkflowLink
- (void) pulse:(NSInteger)indexEpisode;
@end
@implementation LSWLinkEventChangeUnwatchedEpisodes

SYNTHESIZE_WL_DATA_ACCESSOR_NEW(LSDataControllerShowDetails);

- (void) input
{
}

- (void) pulse:(NSInteger)indexEpisode;
{
  LSEpisodeInfo* episode = self.data.episodesSorted[indexEpisode];
  //
  self.data.flagRemove = [self.data isEpisodeUnwatchedWithNumber:episode.number];
  self.data.episodesToChange = [NSArray arrayWithObject:episode];
  [self output];
}

@end


//
// LSControllerShowDetails
//

@implementation LSControllerShowDetails
{
  IBOutlet UIBarButtonItem* theButtonChangeFollowing;
  IBOutlet UIImageView* theImageShow;
  IBOutlet UILabel* theLabelShowTitle;
  IBOutlet UILabel* theLabelShowTitleOriginal;
  IBOutlet UILabel* theLabelShowDetails;
  IBOutlet UITableView* theTableEpisodes;
  //
  NSString* theIdController;
  // workflow
  WFWorkflow* theWorkflow;
  WFLinkLockerDisposable* theWLinkLockWaitForViewDidLoad;
  LSWLinkCollectionEpisodes* theWLinkCollectionEpisodes;
  LSWLinkEventChangeFollowing* theWLinkEventChangeFollowing;
  LSWLinkEventChangeUnwatchedEpisodes* theWLinkEventChangeUnwatchedEpisodes;
  //
  LSMessageMBH* theMessageChangeFollowing;
}

- (IBAction) clickedButtonChangeFollowing:(id)sender
{
  [theWLinkEventChangeFollowing pulse];
}

-(void) didSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
  {
    CGPoint tapLocation = [gestureRecognizer locationInView:theTableEpisodes];
    NSIndexPath *indexPathTapped = [theTableEpisodes indexPathForRowAtPoint:tapLocation];
    if (indexPathTapped)
    {
      [theWLinkEventChangeUnwatchedEpisodes pulse:indexPathTapped.row];
    }
  }
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  //
  [self registerGestureSingleTap];
  //
  [theWLinkLockWaitForViewDidLoad use];
}

- (void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  //
  if (self.isMovingFromParentViewController || self.isBeingDismissed)
  {
    [[LSApplication singleInstance].registryControllers removeController:theIdController];
    theIdController = @"";
  }
}

- (void) registerGestureSingleTap
{
  UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSingleTap:)];
  singleTap.numberOfTapsRequired = 1;
  singleTap.numberOfTouchesRequired = 1;
  [theTableEpisodes addGestureRecognizer:singleTap];
}

- (NSString*) stringFromDate:(NSDate*) date withFormat:(NSString*)format
{
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:format];
  [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
  [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ru_RU"]];
  return [dateFormatter stringFromDate:date];
}

- (NSString*) formatSeasonTitle:(LSShowInfo*)info
{
  return [NSString stringWithFormat:@"%@", info.title];
}

- (NSString*) formatSeasonTitleOriginal:(LSShowInfo*)info
{
  return [NSString stringWithFormat:@"(%@)", info.originalTitle];
}

- (NSString*) formatSeasonDetails:(LSShowInfo*)info
{
  return [NSString stringWithFormat:@"Season %ld, %ld", info.seasonNumber, info.year];
}

- (NSString*) formatEpisodeName:(LSEpisodeInfo*)info
{
  return [NSString stringWithFormat:@"%@", info.name];
}

- (NSString*) formatEpisodeNameOriginal:(LSEpisodeInfo*)info
{
  return [NSString stringWithFormat:@"(%@)", info.originalName];
}

- (NSString*) formatEpisodeDetails:(LSEpisodeInfo*)info
{
  NSString* date = [self stringFromDate:info.dateTranslate withFormat:@"dd.MM.yyyy HH:mm"];
  return [NSString stringWithFormat:@"Episode %ld | %@", info.number, date];
}


#pragma mark -- UITableViewDataSource


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
  return [theWLinkCollectionEpisodes numberOfItems];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  LSTableViewCellEpisodeInfo* cell = (LSTableViewCellEpisodeInfo*)[tableView dequeueReusableCellWithIdentifier:@"theEpisodeCell"];
  if (cell)
  {
    LSEpisodeInfo* info = [theWLinkCollectionEpisodes itemAtIndex:indexPath];
    BOOL isEpisodeUnwatched = [theWLinkCollectionEpisodes isUnwatchedItemAtIndex:indexPath];
    //
    cell.theEpisodeName.text = [self formatEpisodeName:info];
    cell.theEpisodeNameOriginal.text = [self formatEpisodeNameOriginal:info];
    cell.theEpisodeDetails.text = [self formatEpisodeDetails:info];
    cell.theImageMarkWatchingInfo.image = [UIImage imageNamed:isEpisodeUnwatched ? @"MarkUnwatched" : @"MarkWatched"];
  }
  return cell;
}


#pragma mark -- UITableViewDelegate


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // fix size from IB
  LSTableViewCellEpisodeInfo* cell = (LSTableViewCellEpisodeInfo*)[tableView dequeueReusableCellWithIdentifier:@"theEpisodeCell"];
  return cell.frame.size.height;
}


#pragma mark -- View's


- (void) setImageArtwork:(UIImage*)image
{
  theImageShow.image = image;
}

- (void) setShowInfo:(LSShowInfo*)info
{
  theLabelShowTitle.text = [self formatSeasonTitle:info];
  theLabelShowTitleOriginal.text = [self formatSeasonTitleOriginal:info];
  theLabelShowDetails.text = [self formatSeasonDetails:info];
}

- (void) setIsFollowing:(BOOL)isFollowing
{
  theButtonChangeFollowing.title = isFollowing ? @"Unfollow" : @"Follow";
}

- (void) reloadCollectionEpisodes
{
  [theTableEpisodes reloadData];
}

- (void) updateActionIndicatorChangeFollowing:(BOOL)flag
{
  if (flag)
  {
    theMessageChangeFollowing = [[LSApplication singleInstance].messageBlackHole queueManagedNotification:@"Following new shows..." delay:1.];
  }
  else
  {
    [[LSApplication singleInstance].messageBlackHole closeMessage:theMessageChangeFollowing];
  }  
}

- (void) updateActionIndicatorChangeUnwatchedEpisodes:(BOOL)flag
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = flag;
}


#pragma mark -- LSBaseController


- (NSString*) idController
{
  return theIdController;
}

- (void) setIdController:(NSString*)id
{
  theIdController = id;
  [[LSApplication singleInstance].registryControllers registerController:self withIdentifier:id];
}

- (NSString*) idControllerShort
{
  return LSControllerShowDetailsShortID;
}

- (WFWorkflow*) workflow:(LSDataControllerShowDetails*)model
{
  if (theWorkflow)
  {
    return theWorkflow;
  }
  //
  theWLinkLockWaitForViewDidLoad = [[WFLinkLockerDisposable alloc] init];
  theWLinkCollectionEpisodes = [[LSWLinkCollectionEpisodes alloc] initWithData:model view:self];
  theWLinkEventChangeFollowing = [[LSWLinkEventChangeFollowing alloc] initWithData:model view:self];
  theWLinkEventChangeUnwatchedEpisodes = [[LSWLinkEventChangeUnwatchedEpisodes alloc] initWithData:model];
  //
  theWorkflow = WFLinkWorkflow(
      theWLinkLockWaitForViewDidLoad
    , [[LSWLinkShowDescription alloc] initWithData:model view:self]
    , [[LSWLinkActionGetFullSizeArtwork alloc] initWithData:model view:self]
    , theWLinkCollectionEpisodes
    , WFSplitWorkflowWithOutputUsingOr(
          WFLinkWorkflow(
              theWLinkEventChangeFollowing
            , [[LSWLinkSetupActionChangeFollowing alloc] initWithData:model]
            , [[LSWLinkActionChangeFollowing alloc] initWithData:model view:self]
            , nil)
        , WFLinkWorkflow(
              theWLinkEventChangeUnwatchedEpisodes
            , [[LSWLinkActionChangeUnwatchedEpisodes alloc] initWithData:model view:self]
            , nil)
        , nil)
   , nil);
  return theWorkflow;
}

@end


NSString* LSControllerShowDetailsShortID = @"LSControllerShowDetails";
