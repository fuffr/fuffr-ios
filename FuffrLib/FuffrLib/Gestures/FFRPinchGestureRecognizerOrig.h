//
//  FFRPinchGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-12.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"


/**
 Pinch/zoom recognizer (untested)
 */
@interface FFRPinchGestureRecognizer : FFRGestureRecognizer {
    CGPoint _centerPoint;

    NSMutableDictionary* _distances;
    CGFloat _scaleFactor;
}

/**
 Scaling that the recognizer has read
 */
@property (nonatomic, assign) CGFloat scale;

@end
