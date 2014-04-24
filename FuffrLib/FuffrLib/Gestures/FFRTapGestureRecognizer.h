//
//  FFRTapGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-31.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRGestureRecognizer.h"

/**
 * A tap gesture recognizer.
 */
@interface FFRTapGestureRecognizer : FFRGestureRecognizer

/**
 * The tracked touch.
 */
@property (nonatomic, weak) FFRTouch* touch;

@property NSTimeInterval startTime;

@property CGPoint startPoint;

@end
