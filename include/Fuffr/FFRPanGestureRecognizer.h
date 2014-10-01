//
//  FFRPanGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"
#import "FFRLowPassFilter.h"

/**
 * A panning gesture recognizer.
 */
@interface FFRPanGestureRecognizer : FFRGestureRecognizer

/**
 * Current translation of the panning gesture.
 */
@property (nonatomic, assign) CGSize translation;

/**
 * The maximum distance between touch points for the
 * gesture to be considered beeing a panning gesture.
 */
@property (nonatomic, assign) CGFloat maximumTouchDistance;

/**
 * The first point of a touch sequence, this point
 * is used as the center point of the pan (coordinate 0,0).
 */
@property (nonatomic, assign) CGPoint startPoint;

/**
 * The tracked touch.
 */
@property (nonatomic, weak) FFRTouch* touch;

/**
 * The second touch.
 */
@property (nonatomic, weak) FFRTouch* touch2;

@property FFRLowPassFilter* lowPassFilterX;
@property FFRLowPassFilter* lowPassFilterY;

@end
