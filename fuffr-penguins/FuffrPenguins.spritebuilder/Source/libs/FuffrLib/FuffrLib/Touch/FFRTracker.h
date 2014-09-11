//
//  FFRTracker.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-24.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRTouch.h"

/**
    Protocol for views/objects that monitor touches
 */
@protocol FFRTracker <NSObject>

/**
    Initialize a tracker for the touch object
  */
- (id)initWithTracking:(FFRTouch*)data;

/**
    The tracked touch
 */
@property (nonatomic, weak) FFRTouch* trackedData;

@end
