//
//  LSRegistryControllers.h
//  LostSeries
//
//  Created by Grigory Zubankov on 04/04/14.
//  Copyright (c) 2014 Grigory Zubankov. All rights reserved.
//

// Foundation
#import <Foundation/Foundation.h>

//
// LSRegistryControllers
//

@interface LSRegistryControllers : NSObject

#pragma mark - Init Methods
- (id) init;

#pragma mark - Interface

- (void) registerController:(id)controller withIdentifier:(NSString*)identifier;
- (void) removeController:(NSString*)identifier;
- (id) findControllerByIdentifier:(NSString*)identifier;

@end
