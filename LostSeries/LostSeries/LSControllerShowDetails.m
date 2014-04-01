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
// LSControllerShowDetails
//

@implementation LSControllerShowDetails
{
  IBOutlet UIImageView* theImageShow;
  IBOutlet UITableView* theTableEpisodes;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  //
  LSShowAlbumCellModel* info = [LSApplication singleInstance].modelBase.shows[0];
  theImageShow.image = info.artwork;
}

@end
