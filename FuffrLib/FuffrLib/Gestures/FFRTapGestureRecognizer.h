//
//  FFRTapGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-31.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRGestureRecognizer.h"

/**
 * A tap gesture recognizer.
 */
@interface FFRTapGestureRecognizer : FFRGestureRecognizer

/**
 * User settable. Max time for finger down to be 
 * considered a tap gesture.
 */
@property NSTimeInterval maximumDuration;

/**
 * User settable. Max distance for finger to move to be 
 * considered a tap gesture.
 */
@property CGFloat maximumDistance;

/**
 * Internal. The tracked touch.
 */
@property (nonatomic, weak) FFRTouch* touch;

/**
 * Internal. Start time of the touch.
 */
@property NSTimeInterval startTime;

/**
 * Internal. Start point of the touch.
 */
@property CGPoint startPoint;

@end
