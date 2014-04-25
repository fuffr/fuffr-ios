//
//  FFRSwipeGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"

typedef enum
{
	FFRSwipeGestureRecognizerDirectionRight = 0x1,
	FFRSwipeGestureRecognizerDirectionLeft  = 0x2,
	FFRSwipeGestureRecognizerDirectionUp	= 0x4,
	FFRSwipeGestureRecognizerDirectionDown  = 0x8
}
FFRSwipeGestureRecognizerDirection;

/**
 A swipe gesture recognizer
 */
@interface FFRSwipeGestureRecognizer : FFRGestureRecognizer

/**
 * User settable. The recognized direction that the swipe gesture.
 */
@property FFRSwipeGestureRecognizerDirection direction;

/**
 * User setable. The max time for a swipe gesture.
 */
@property NSTimeInterval maximumDuration;

/**
 * User settable. The minimum distance for finger to move to be
 * considered a swipe gesture.
 */
@property CGFloat minimumDistance;

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
