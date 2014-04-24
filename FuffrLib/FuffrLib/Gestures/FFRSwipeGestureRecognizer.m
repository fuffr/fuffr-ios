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
        self.state = FFRGestureRecognizerStateBegan;
    }
    else if (self.state == FFRGestureRecognizerStateBegan) {
        if (end - _start <= 0.5) {
            CGFloat distance = [self maxDistanceBetween:_startPoint andPoint:endPoint];
            if (distance > 30) {
                if (self.direction == FFRSwipeGestureRecognizerDirectionRight && ABS(_startPoint.x - endPoint.x) > ABS(_startPoint.y - endPoint.y) && endPoint.x > _startPoint.x) {
                    [self performAction];
                    self.state = FFRGestureRecognizerStateEnded;
                }
                else if (self.direction == FFRSwipeGestureRecognizerDirectionLeft && ABS(_startPoint.x - endPoint.x) > ABS(_startPoint.y - endPoint.y) && _startPoint.x > endPoint.x) {
                    [self performAction];
                    self.state = FFRGestureRecognizerStateEnded;
                }
                else if (self.direction == FFRSwipeGestureRecognizerDirectionUp && ABS(_startPoint.y - endPoint.y) > ABS(_startPoint.x - endPoint.x) && _startPoint.y > endPoint.y) {
                    [self performAction];
                    self.state = FFRGestureRecognizerStateEnded;
                }
                else if (self.direction == FFRSwipeGestureRecognizerDirectionDown && ABS(_startPoint.y - endPoint.y) > ABS(_startPoint.x - endPoint.x) && endPoint.y > _startPoint.y) {
                    [self performAction];
                    self.state = FFRGestureRecognizerStateEnded;
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
    self.state = FFRGestureRecognizerStateEnded;
}

@end
