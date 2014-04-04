//
//  FFRPinchGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-12.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRPinchGestureRecognizer.h"
#import "FFRTouch.h"
//#define LOGMETHOD NSLog(@"%@/%@",[self class],NSStringFromSelector(_cmd));

@implementation FFRPinchGestureRecognizer


@synthesize scale = _scale;


-(id) init {
    if (self = [super init]) {
        _distances = [NSMutableDictionary dictionary];
        _scaleFactor = 1;
    }

    return self;
}


-(void) setScale:(CGFloat)scale {
    _scaleFactor = _scaleFactor / _scale * scale;
    _scale = scale;
}


#pragma mark - Touch handling

-(void) touchesBegan:(NSSet*)touches {
    LOGMETHOD

	NSLog(@"Touches count: %i", touches.count);

    self.state = ([touches count] >= 2) ? UIGestureRecognizerStateBegan : UIGestureRecognizerStatePossible;

    _centerPoint = CGPointZero;
    float factor = 1.0 / [touches count];
    for (FFRTouch* touch in touches) {
        _centerPoint = CGPointMake(_centerPoint.x + factor*touch.location.x, _centerPoint.y + factor*touch.location.y);

        [_distances setObject:[NSNumber numberWithDouble:[self distanceBetween:_centerPoint andPoint:touch.location]] forKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

-(void) touchesMoved:(NSSet *)touches {
    LOGMETHOD

	//NSLog(@"Touches count: %i", touches.count);

    if (self.state == UIGestureRecognizerStateBegan) {
        for (FFRTouch* touch in touches) {
            CGFloat newDistance = [self distanceBetween:_centerPoint andPoint:touch.location];
            CGFloat oldDistance = [(NSNumber*)[_distances objectForKey:[NSString stringWithFormat:@"%p", touch]] doubleValue];
            if (ABS(newDistance - oldDistance) > 10) {
				NSLog(@"UIGestureRecognizerStateChanged: %f", ABS(newDistance - oldDistance));
                self.state = UIGestureRecognizerStateChanged;
                break;
            }
        }
    }
    else if (self.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointZero;
        float factor = 1.0 / [touches count];
        for (FFRTouch* touch in touches) {
            newCenter = CGPointMake(_centerPoint.x + factor*touch.location.x, _centerPoint.y + factor*touch.location.y);
        }

        CGFloat newScale = 0;
        for (FFRTouch* touch in touches) {
            CGFloat oldDistance = [(NSNumber*)[_distances objectForKey:[NSString stringWithFormat:@"%p", touch]] doubleValue];
            CGFloat newDistance = [self distanceBetween:newCenter andPoint:touch.location];

            newScale = MAX(newScale, newDistance / oldDistance);

            [_distances setObject:[NSNumber numberWithDouble:newDistance] forKey:[NSString stringWithFormat:@"%p", touch]];
        }

        _scale = newScale * _scaleFactor;
        [self performAction];
    }
}

-(void) touchesEnded:(NSSet *)touches {
    LOGMETHOD

    for (FFRTouch* touch in touches) {
        if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
            [_distances removeObjectForKey:[NSString stringWithFormat:@"%p", touch]];
        }
    }

    self.state = ([touches count] >= 2) ? UIGestureRecognizerStateChanged : UIGestureRecognizerStateEnded;
}

-(void) touchesCancelled:(NSSet *)touches {
    LOGMETHOD

    for (FFRTouch* touch in touches) {
        if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
            [_distances removeObjectForKey:[NSString stringWithFormat:@"%p", touch]];
        }
    }

    self.state = ([touches count] >= 2) ? UIGestureRecognizerStateChanged : UIGestureRecognizerStateCancelled;
}

@end
