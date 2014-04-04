//
//  FFRPinchGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2014-03-27.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"
#import "FFRLowPassFilter.h"

/**
 * Pinch/zoom recognizer (new version).
 */
@interface FFRPinchGestureRecognizer : FFRGestureRecognizer

/**
 * Scaling of the pinch.
 */
@property (nonatomic, assign) CGFloat scale;

/**
 * The minimum distance between touch points for the
 * gesture to be considered as a pinch.
 */
@property (nonatomic, assign) CGFloat minimumTouchDistance;

@property (nonatomic, assign) CGFloat pinchThresholdTouchDistance;

@property (nonatomic, weak) FFRTouch* touch1;
@property (nonatomic, weak) FFRTouch* touch2;

@property (nonatomic, assign) CGFloat startDistance;

@property (nonatomic, assign) CGFloat previousDistance;

@end
