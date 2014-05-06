//
//  LSModelShow.h
//  LostSeries
//
//  Created by Grigory Zubankov on 05/05/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>
// LS
#import "Remote/LSAsyncBackendFacade.h"


//
// LSShowAlbumCellModel
//

@interface LSShowAlbumCellModel : NSObject
@property LSShowInfo* showInfo;
@property UIImage* artwork;
@end
