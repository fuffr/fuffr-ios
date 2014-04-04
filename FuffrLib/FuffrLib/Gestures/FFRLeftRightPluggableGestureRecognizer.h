//
//  FFRLeftRightPluggableGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2014-04-01.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"

/**
 * A gesture recognizer that operates on one left and one right side touch.
 */
@interface FFRLeftRightPluggableGestureRecognizer : FFRGestureRecognizer

/**
 * Gesture recognizer.
 */
@property FFRGestureRecognizer* myRecognizer;

/**
 * The tracked touch points.
 */
@property (nonatomic, weak) FFRTouch* touchLeft;
@property (nonatomic, weak) FFRTouch* touchRight;

- (void) setGestureRecognizer: (id)recognizer;

@end
