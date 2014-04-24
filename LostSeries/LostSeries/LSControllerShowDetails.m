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
// WF
#import <WorkflowLink/WorkflowLink.h>
#import <WorkflowLink/WFLinkLockerDisposable.h>


@interface LSTableViewCellEpisodeInfo : UITableViewCell
@property IBOutlet UILabel* theEpisodeName;
@property IBOutlet UILabel* theEpisodeNameOriginal;
@property IBOutlet UILabel* theEpisodeDetails;
@end
@implementation LSTableViewCellEpisodeInfo
@end


//
// LSWLinkShowDescription
//

@interface LSWLinkShowDescription : WFWorkflowLink
@end
@implementation LSWLinkShowDescription

SYNTHESIZE_WL_ACCESSORS_NEW(LSModelBase, LSViewShowDescription);

- (void) input
{
  [self.view setShowInfo:self.data.showForDetails.showInfo];
  [self output];
}

@end


//
// LSWLinkActionGetFullSizeArtwork
//

@interface LSWLinkActionGetFullSizeArtwork : WFWorkflowLink
@end
@implementation LSWLinkActionGetFullSizeArtwork

SYNTHESIZE_WL_ACCESSORS_NEW(LSModelBase, LSViewActionGetFullSizeArtwork);

- (void) input
{
  [self.data.backendFacade getArtworkByShowInfo:self.data.showForDetails.showInfo thumbnail:NO replyHandler:^(NSData* dataArtwork)
  {
    [self.view setImageArtwork: [UIImage imageWithData:dataArtwork]];
    [self output];
  }];
  // set thumbnail at first
  if (self.data.showForDetails.artwork)
  {
    [self.view setImageArtwork:self.data.showForDetails.artwork];
  }
  [self output];
}

@end


//
// LSWLinkCollectionEpisodes
//

@interface LSWLinkCollectionEpisodes : WFWorkflowLink

- (LSEpisodeInfo*) itemAtIndex:(NSIndexPath*)indexPath;
- (NSUInteger) numberOfItems;

@end

@implementation LSWLinkCollectionEpisodes
{
  NSArray* theEpisodesSorted;
}

SYNTHESIZE_WL_DATA_ACCESSOR(LSDataBaseModelShowForDatails);

- (LSEpisodeInfo*) itemAtIndex:(NSIndexPath*)indexPath
{
  return theEpisodesSorted[indexPath.row];
}

- (NSUInteger) numberOfItems
{
  return theEpisodesSorted.count;
}

- (void) input
{
  theEpisodesSorted = [self.data.showForDetails.showInfo.episodes sortedArrayUsingComparator:^NSComparisonResult(LSEpisodeInfo* left, LSEpisodeInfo* right)
  {
    return [[NSNumber numberWithInteger:right.number] compare:[NSNumber numberWithInteger:left.number]];
  }];
  [self output];
}

@end


//
// LSWLinkButtonChangeFollowing
//

@interface LSWLinkButtonChangeFollowing : WFWorkflowLink
- (void) clicked;
@end

@implementation LSWLinkButtonChangeFollowing

SYNTHESIZE_WL_ACCESSORS_NEW(LSModelBase, LSViewButtonChangeFollowing);

- (void) input
{
  [self update];
}

- (void) update
{
  [self.view setTextButtonChangeFollowing:self.isShowFollowing ? @"Unfollow" : @"Follow"];
}

- (void) clicked
{
  self.data.followingModeFollow = !self.isShowFollowing;
  [self addShowToListChangeFollowing];
  //
  [self output];
}

- (BOOL) isShowFollowing
{
  for (LSShowAlbumCellModel* show in self.data.showsFollowing)
  {
    if (show.showInfo.showID == self.data.showForDetails.showInfo.showID)
    {
      return YES;
    }
  }
  return NO;
}

- (void) addShowToListChangeFollowing
{
  [self.data.modelShowsLists.showsToChangeFollowing removeAllObjectes];
  //
  for (NSInteger i = 0; i < self.data.modelShowsLists.shows.count; ++i)
  {
    LSShowAlbumCellModel* show = self.data.modelShowsLists.shows[i];
    if (show.showInfo.showID == self.data.showForDetails.showInfo.showID)
    {
      [self.data.modelShowsLists.showsToChangeFollowing addObjectByIndexSource:i];
      break;
    }
  }
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
  LSWLinkButtonChangeFollowing* theWLinkButtonChangeFollowing;
  //
  LSMessageMBH* theMessageChangeFollowing;
}

- (IBAction) clickedButtonChangeFollowing:(id)sender;
{
  [theWLinkButtonChangeFollowing clicked];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  //
  [theWLinkLockWaitForViewDidLoad use];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  //
  if (self.isMovingFromParentViewController || self.isBeingDismissed)
  {
    [[LSApplication singleInstance].registryControllers removeController:theIdController];
    theIdController = @"";
  }
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

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
  return [theWLinkCollectionEpisodes numberOfItems];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  LSTableViewCellEpisodeInfo* cell = (LSTableViewCellEpisodeInfo*)[tableView dequeueReusableCellWithIdentifier:@"theEpisodeCell"];
  if (cell)
  {
    LSEpisodeInfo* info = [theWLinkCollectionEpisodes itemAtIndex:indexPath];
    cell.theEpisodeName.text = [self formatEpisodeName:info];
    cell.theEpisodeNameOriginal.text = [self formatEpisodeNameOriginal:info];
    cell.theEpisodeDetails.text = [self formatEpisodeDetails:info];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // fix size from IB
  LSTableViewCellEpisodeInfo* cell = (LSTableViewCellEpisodeInfo*)[tableView dequeueReusableCellWithIdentifier:@"theEpisodeCell"];
  return cell.frame.size.height;
}

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

- (void) setTextButtonChangeFollowing:(NSString*)text
{
  theButtonChangeFollowing.title = text;
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


#pragma mark - LSBaseController implementation


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

- (WFWorkflow*) workflow
{
  if (theWorkflow)
  {
    return theWorkflow;
  }
  //
  LSModelBase* model = [LSApplication singleInstance].modelBase;
  theWLinkLockWaitForViewDidLoad = [[WFLinkLockerDisposable alloc] init];
  theWLinkCollectionEpisodes = [[LSWLinkCollectionEpisodes alloc] initWithData:model];
  theWLinkButtonChangeFollowing = [[LSWLinkButtonChangeFollowing alloc] initWithData:model view:self];
  //
  theWorkflow = WFLinkWorkflow(
      theWLinkLockWaitForViewDidLoad
    , [[LSWLinkShowDescription alloc] initWithData:model view:self]
    , [[LSWLinkActionGetFullSizeArtwork alloc] initWithData:model view:self]
    , theWLinkCollectionEpisodes
    , theWLinkButtonChangeFollowing
    , [[LSWLinkActionChangeFollowing alloc] initWithData:[LSApplication singleInstance].modelBase view:self]
    , nil);
  return theWorkflow;
}

@end


NSString* LSControllerShowDetailsShortID = @"LSControllerShowDetails";
