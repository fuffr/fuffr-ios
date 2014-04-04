//
//  FFRSwipeGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"


/**
 A swipe gesture recognizer
 */
@interface FFRSwipeGestureRecognizer : FFRGestureRecognizer {
    NSTimeInterval _start;
    CGPoint _startPoint;
}

/**
 The direction that the recognizer is listening for
 */
@property (nonatomic, assign) UISwipeGestureRecognizerDirection direction;

@end
