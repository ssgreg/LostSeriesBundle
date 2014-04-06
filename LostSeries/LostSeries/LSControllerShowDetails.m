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


//
// LSWLinkLockWaitForViewDidLoad
//

@interface LSWLinkLockWaitForViewDidLoad : WFWorkflowLink
@end

@implementation LSWLinkLockWaitForViewDidLoad
{
  BOOL theIsLockedFlag;
}

- (void) unlock
{
  theIsLockedFlag = NO;
  [self input];
}

- (void) update
{
  theIsLockedFlag = YES;
}

- (void) input
{
  if (theIsLockedFlag)
  {
    [self forwardBlock];
  }
  else
  {
    [self output];
  }
}

@end


//
// LSWLinkActionGetFullSizeArtwork
//

@protocol LSDataActionGetFullSizeArtwork <LSDataBaseFacadeAsyncBackend, LSDataBaseModelShowForDatails>
@end

@interface LSWLinkActionGetFullSizeArtwork : WFWorkflowLink
@end

@implementation LSWLinkActionGetFullSizeArtwork

SYNTHESIZE_WL_ACCESSORS(LSDataActionGetFullSizeArtwork, LSViewActionGetFullSizeArtwork);

- (void) input
{
  [self.data.backendFacade getArtworkByShowInfo:self.data.showForDetails.showInfo thumbnail:NO replyHandler:^(NSData* dataArtwork)
  {
    [self.view setImageArtwork: [UIImage imageWithData:dataArtwork]];
    [self output];
  }];
  // set thumbail at first
  if (self.data.showForDetails.artwork)
  {
    [self.view setImageArtwork:self.data.showForDetails.artwork];
  }
  [self output];
}

@end


//
// LSControllerShowDetails
//

@implementation LSControllerShowDetails
{
  IBOutlet UIImageView* theImageShow;
  IBOutlet UITableView* theTableEpisodes;
  //
  NSString* theIdController;
  // workflow
  WFWorkflow* theWorkflow;
  LSWLinkLockWaitForViewDidLoad* theWLinkLockWaitForViewDidLoad;
}
 
- (void) setIdController:(NSString*)id
{
  theIdController = id;
  [[LSApplication singleInstance].registryControllers registerController:self withIdentifier:id];
}

- (WFWorkflow*) workflow
{
  if (theWorkflow)
  {
    return theWorkflow;
  }
  //
  LSModelBase* model = [LSApplication singleInstance].modelBase;
  theWLinkLockWaitForViewDidLoad = [[LSWLinkLockWaitForViewDidLoad alloc] init];
  //
  theWorkflow = WFLinkWorkflow(
      theWLinkLockWaitForViewDidLoad
    , [[LSWLinkActionGetFullSizeArtwork alloc] initWithData:model view:self]
    , nil);
  return theWorkflow;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  [theWLinkLockWaitForViewDidLoad unlock];
//  LSShowAlbumCellModel* info = [LSApplication singleInstance].modelBase.shows[0];
//  theImageShow.image = info.artwork;
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

- (void) setImageArtwork:(UIImage*)image
{
  theImageShow.image = image;
}

@end
