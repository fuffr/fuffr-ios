//
//  FFRRotationGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-12.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"


/**
 Rotation recognizer (untested)
 */
@interface FFRRotationGestureRecognizer : FFRGestureRecognizer {
    CGFloat _rotationLock;
    BOOL _unlocked;
}

/**
 Rotation that the recognizer has read
 */
@property (nonatomic, assign) CGFloat rotation;

@end
