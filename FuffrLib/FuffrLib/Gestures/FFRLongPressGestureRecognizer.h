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
@interface FFRLongPressGestureRecognizer : FFRGestureRecognizer {
    NSTimeInterval _startTime;
    CGPoint _startPoint;

    NSTimeInterval _currentTime;
    CGPoint _currentPoint;

    NSTimer* _timer;
}

@end
