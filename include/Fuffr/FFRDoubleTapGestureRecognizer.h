//
//  FFRDoubleTapGestureRecognizer.h
//  FuffrLib
//
//  Created by Mac Builder on 4/23/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRGestureRecognizer.h"

@interface FFRDoubleTapGestureRecognizer : FFRGestureRecognizer

/**
 * User settable. Max time for finger down to be 
 * considered a double tap gesture.
 */
@property NSTimeInterval maximumDuration;

/**
 * User settable. Max distance for finger to move to be 
 * considered a double tap gesture.
 */
@property CGFloat maximumDistance;

/**
 * Internal. The tracked touch.
 */
@property (nonatomic, weak) FFRTouch* touch;

/**
 * Internal. Number of touches within a doube tap gesture.
 */
@property (assign) NSInteger touchCount;

/**
 * Internal. Start time of the touch.
 */
@property NSTimeInterval startTime;

/**
 * Internal. Start point of the touch.
 */
@property CGPoint startPoint;

@end
