//
//  FFRLongPressGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRLongPressGestureRecognizer.h"
#import "FFRTouch.h"

@implementation FFRLongPressGestureRecognizer


-(void) touchesBegan:(NSSet*)touches {
    LOGMETHOD

    for (FFRTouch* touch in touches) {
        _startTime = touch.timestamp;
        _startPoint = touch.location;
    }

    self.state = FFRGestureRecognizerStateBegan;

    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerFired:) userInfo:nil repeats:FALSE];
}

-(void) touchesMoved:(NSSet *)touches {
    LOGMETHOD
    //NSLog(@"touchesMoved: %@ - %@", touches, event);

    for (FFRTouch* touch in touches) {
        _currentTime = touch.timestamp;
        _currentPoint = touch.location;
    }

    if (self.state == UIGestureRecognizerStateRecognized || self.state == FFRGestureRecognizerStateChanged) {
        self.state = FFRGestureRecognizerStateChanged;
        [self performAction];
    }
}

-(void) touchesEnded:(NSSet *)touches {
    LOGMETHOD

    _startPoint = CGPointZero;
    _startTime = 0;

    //NSLog(@"touchesEnded: %@ - %@", touches, event);
    if (self.state == UIGestureRecognizerStateRecognized || self.state == FFRGestureRecognizerStateChanged) {
        self.state = FFRGestureRecognizerStateEnded;
        [self performAction];
    }

    self.state = FFRGestureRecognizerStateEnded;
}

-(void) touchesCancelled:(NSSet *)touches {
    LOGMETHOD

    //NSLog(@"touchesCancelled: %@ - %@", touches, event);

    _startPoint = CGPointZero;
    _startTime = 0;

    for (FFRTouch* touch in touches) {
        //CGPoint p = [touch locationInView:self.view];
        //NSLog(@"movement: %f,%f, %f", p.x - _point.x, p.y - _point.y, [[NSDate date] timeIntervalSinceDate:_start]);
        NSLog(@"time: %f", touch.timestamp - _startTime);
    }

    if (self.state == UIGestureRecognizerStateRecognized || self.state == FFRGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateCancelled;
        [self performAction];
    }

    self.state = UIGestureRecognizerStateCancelled;
}

#pragma mark - Timer

-(void) timerFired:(id)sender {
    CGFloat distance = [self maxDistanceBetween:_startPoint andPoint:_currentPoint];

    if (distance < 10 && self.state == FFRGestureRecognizerStateBegan) {
        self.state = UIGestureRecognizerStateRecognized;
        [self performAction];
    }
    else {
        self.state = UIGestureRecognizerStateCancelled;
        _timer = nil;
    }
}

@end
