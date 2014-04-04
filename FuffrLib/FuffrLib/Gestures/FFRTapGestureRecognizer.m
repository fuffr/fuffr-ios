//
//  FFRTapGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-31.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRTapGestureRecognizer.h"
#import "FFRTouch.h"


@implementation FFRTapGestureRecognizer

// TODO: Unused, remove.
//@synthesize view = _view;

#pragma mark - touch debug

-(void) touchesBegan:(NSSet*)touches {
    LOGMETHOD

    //NSLog(@"touchesBegan: %@ - %@", touches, event);
    for (FFRTouch* touch in touches) {
        _start = touch.timestamp;
        _startPoint = touch.location;
    }

    self.state = UIGestureRecognizerStateBegan;
}

-(void) touchesMoved:(NSSet *)touches {
    LOGMETHOD
    //NSLog(@"touchesMoved: %@ - %@", touches, event);
}

-(void) touchesEnded:(NSSet *)touches {
    LOGMETHOD

    //NSLog(@"touchesEnded: %@ - %@", touches, event);

    CGPoint endPoint;
    NSTimeInterval end;
    for (FFRTouch* touch in touches) {
        endPoint = touch.location;
        end = touch.timestamp;
    }

    CGFloat distance = [self maxDistanceBetween:_startPoint andPoint:endPoint];
    //NSLog(@"Tap diff: %f %f %f", end, _start, end - _start);
    if (distance < 10 && end - _start < 1.5) {
        [self performAction];
    }

    self.state = UIGestureRecognizerStateEnded;
}

-(void) touchesCancelled:(NSSet *)touches {
    LOGMETHOD

    //NSLog(@"touchesCancelled: %@ - %@", touches, event);
    _startPoint = CGPointZero;
    _start = 0;

    for (FFRTouch* touch in touches) {
        //NSLog(@"movement: %f,%f, %f", p.x - _point.x, p.y - _point.y, [[NSDate date] timeIntervalSinceDate:_start]);
        NSLog(@"time: %f", touch.timestamp - _start);
    }

    self.state = UIGestureRecognizerStateCancelled;
}

@end
