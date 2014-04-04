//
//  FFRPanGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRPanGestureRecognizer.h"
#import "FFRTouch.h"

@implementation FFRPanGestureRecognizer


@synthesize translation = _translation;


-(void) setTranslation:(CGSize)translation {
    _resetPoint = CGPointMake(_startPoint.x + _translation.width - translation.width, _startPoint.y + _translation.height - translation.height);
    _translation = translation;
}


#pragma mark - Touch handling

-(void) touchesBegan:(NSSet*)touches {
    LOGMETHOD

    for (FFRTouch* touch in touches)
    {
        _startPoint = touch.location;
    }

    _resetPoint = _startPoint;

    self.state = UIGestureRecognizerStateBegan;
}

-(void) touchesMoved:(NSSet *)touches {
    LOGMETHOD
    //NSLog(@"touchesMoved: %@ - %@", touches, event);

    CGPoint currentPoint;
    for (FFRTouch* touch in touches) {
        currentPoint = touch.location;
    }

    _translation = CGSizeMake(currentPoint.x - _resetPoint.x, currentPoint.y - _resetPoint.y);

    if (self.state == UIGestureRecognizerStateBegan) {
        self.state = UIGestureRecognizerStateRecognized;
    }
    else if (self.state == UIGestureRecognizerStateRecognized) {
        CGFloat distance = [self maxDistanceBetween:_startPoint andPoint:currentPoint];
        if (distance > 10) {
            self.state = UIGestureRecognizerStateChanged;
        }
    }
    else if (self.state == UIGestureRecognizerStateChanged) {
        [self performAction];
    }
}

-(void) touchesEnded:(NSSet *)touches {
    LOGMETHOD

    //NSLog(@"touchesEnded: %@ - %@", touches, event);
    if (self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateEnded;
        [self performAction];
    }

    self.state = UIGestureRecognizerStateEnded;

    _translation = CGSizeZero;
    _startPoint = CGPointZero;
    _resetPoint = CGPointZero;
}

-(void) touchesCancelled:(NSSet *)touches {
    LOGMETHOD

    if (self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateCancelled;
        [self performAction];
    }

    self.state = UIGestureRecognizerStateCancelled;

    _translation = CGSizeZero;
    _startPoint = CGPointZero;
    _resetPoint = CGPointZero;
}

@end
