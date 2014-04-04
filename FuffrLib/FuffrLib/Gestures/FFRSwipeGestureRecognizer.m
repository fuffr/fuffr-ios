//
//  FFRSwipeGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRSwipeGestureRecognizer.h"
#import "FFRTouch.h"


@implementation FFRSwipeGestureRecognizer


-(void) touchesBegan:(NSSet*)touches {
    LOGMETHOD

    //NSLog(@"touchesBegan: %@ - %@", touches, event);
    for (FFRTouch* touch in touches) {
        _start = touch.timestamp;
        _startPoint = touch.location;
    }

    self.state = UIGestureRecognizerStatePossible;
}

-(void) touchesMoved:(NSSet *)touches {
    LOGMETHOD
    //NSLog(@"touchesMoved: %@ - %@", touches, event);

    CGPoint endPoint;
    NSTimeInterval end;
    for (FFRTouch* touch in touches) {
        end = touch.timestamp;
        endPoint = touch.location;
    }

    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateBegan;
    }
    else if (self.state == UIGestureRecognizerStateBegan) {
        if (end - _start <= 0.5) {
            CGFloat distance = [self maxDistanceBetween:_startPoint andPoint:endPoint];
            if (distance > 30) {
                if (self.direction == UISwipeGestureRecognizerDirectionRight && ABS(_startPoint.x - endPoint.x) > ABS(_startPoint.y - endPoint.y) && endPoint.x > _startPoint.x) {
                    [self performAction];
                    self.state = UIGestureRecognizerStateEnded;
                }
                else if (self.direction == UISwipeGestureRecognizerDirectionLeft && ABS(_startPoint.x - endPoint.x) > ABS(_startPoint.y - endPoint.y) && _startPoint.x > endPoint.x) {
                    [self performAction];
                    self.state = UIGestureRecognizerStateEnded;
                }
                else if (self.direction == UISwipeGestureRecognizerDirectionUp && ABS(_startPoint.y - endPoint.y) > ABS(_startPoint.x - endPoint.x) && _startPoint.y > endPoint.y) {
                    [self performAction];
                    self.state = UIGestureRecognizerStateEnded;
                }
                else if (self.direction == UISwipeGestureRecognizerDirectionDown && ABS(_startPoint.y - endPoint.y) > ABS(_startPoint.x - endPoint.x) && endPoint.y > _startPoint.y) {
                    [self performAction];
                    self.state = UIGestureRecognizerStateEnded;
                }
                else {
                    self.state = UIGestureRecognizerStateCancelled;
                    return;
                }
            }
        }
        else  {
            self.state = UIGestureRecognizerStateFailed;
            return;
        }
    }
    else {
        return;
    }
}

-(void) touchesEnded:(NSSet *)touches {
    LOGMETHOD

    //NSLog(@"touchesEnded: %@ - %@", touches, event);
    self.state = UIGestureRecognizerStateEnded;
}

-(void) touchesCancelled:(NSSet *)touches {
    LOGMETHOD

    //NSLog(@"touchesCancelled: %@ - %@", touches, event);

    _startPoint = CGPointZero;
    _start = 0;

    for (FFRTouch* touch in touches) {
        //CGPoint p = [touch locationInView:self.view];
        //NSLog(@"movement: %f,%f, %f", p.x - _point.x, p.y - _point.y, [[NSDate date] timeIntervalSinceDate:_start]);
        NSLog(@"time: %f", touch.timestamp - _start);
    }

    self.state = UIGestureRecognizerStateCancelled;
}

@end
