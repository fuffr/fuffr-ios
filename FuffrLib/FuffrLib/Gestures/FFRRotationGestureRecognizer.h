//
//  FFRRotationGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-12.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"
#import "FFRLowPassFilter.h"

/**
 * Rotation recognizer
 */
@interface FFRRotationGestureRecognizer : FFRGestureRecognizer

/**
 * Current rotation.
 */
@property (nonatomic, assign) CGFloat rotation;

/**
 * The minimum distance between touch points for the
 * gesture to be considered as a rotation.
 */
@property (nonatomic, assign) CGFloat minimumTouchDistance;

@property (nonatomic, assign) CGFloat rotationThreshold;

@property (nonatomic, weak) FFRTouch* touch1;
@property (nonatomic, weak) FFRTouch* touch2;

@property (nonatomic, assign) CGFloat currentRotation;

@property (nonatomic, assign) CGFloat previousRotation;

@property FFRLowPassFilter* lowPassFilter;

@end
