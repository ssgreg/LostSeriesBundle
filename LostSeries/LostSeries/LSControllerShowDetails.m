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
// LSWLinkActionGetFullSizeArtwork
//

@protocol LSDataActionGetFullSizeArtwork <LSDataBaseFacadeAsyncBackend>
@end

@interface LSWLinkActionGetFullSizeArtwork : WFWorkflowLink
@end

@implementation LSWLinkActionGetFullSizeArtwork

SYNTHESIZE_WL_ACCESSORS(LSDataActionGetFullSizeArtwork, LSViewActionGetFullSizeArtwork);

- (void) input
{
  //
//  [self.data.backendFacade getArtworkByShowInfo:<#(LSShowInfo *)#> replyHandler:<#^(NSData *)handler#>:[LSApplication singleInstance].deviceToken subscriptionInfo:self.makeSubscriptions replyHandler:^(BOOL result)
//  {
//    [self.view showActionIndicator:NO];
//    if (result)
//    {
//      [self output];
//    }
//  }];
  //
  [self forwardBlock];
}

@end


//
// LSControllerShowDetails
//

@implementation LSControllerShowDetails
{
  IBOutlet UIImageView* theImageShow;
  IBOutlet UITableView* theTableEpisodes;
  // workflow
  WFWorkflow* theWorkflow;
}
 
@synthesize idController;

- (WFWorkflow*) workflow
{
  return theWorkflow;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  LSShowAlbumCellModel* info = [LSApplication singleInstance].modelBase.shows[0];
  theImageShow.image = info.artwork;
  //
  LSModelBase* model = [LSApplication singleInstance].modelBase;
  //
  theWorkflow = WFLinkWorkflow(
      [[LSWLinkActionGetFullSizeArtwork alloc] initWithData:model view:self]
    , nil);
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  //
  if (self.isMovingFromParentViewController || self.isBeingDismissed)
  {
    [[LSApplication singleInstance].registryControllers removeController:idController];
    idController = @"";
  }
}

@end
