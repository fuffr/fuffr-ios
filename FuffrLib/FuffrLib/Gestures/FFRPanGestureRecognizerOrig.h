//
//  FFRPanGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"


/**
 A pan gesture recognizer,
 Normally you want to reset the translation after reading/updating the interface
 */
@interface FFRPanGestureRecognizer : FFRGestureRecognizer {
    CGPoint _startPoint;
    CGPoint _resetPoint;
}

/**
 Translation that the pan has read
 */
@property (nonatomic, assign) CGSize translation;

@end
