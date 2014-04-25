//
//  FFRLongPressGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"

/**
 A long press gesture recognizer
 */
@interface FFRLongPressGestureRecognizer : FFRGestureRecognizer

/**
 * User settable. Time for finger down to be
 * considered a long press gesture.
 */
@property NSTimeInterval minimumDuration;

/**
 * User settable. Max distance for finger to move to be 
 * considered a long press gesture.
 */
@property CGFloat maximumDistance;

/**
 * Internal properties.
 */
@property FFRTouch* touch;
@property NSTimer* timer;
@property CGPoint startPoint;

@end
