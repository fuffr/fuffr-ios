//
//  FFRDoubleTapGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 4/23/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRDoubleTapGestureRecognizer.h"
#import "FFRTouch.h"


@implementation FFRDoubleTapGestureRecognizer

-(id) init {
    if (self = [super init]) {
        _count = 0;
        _down = false;
    }
    
    return self;
}

#pragma mark - touch debug

-(void) touchesBegan:(NSSet*)touches {
    LOGMETHOD
    
    //NSLog(@"touchesBegan: %@", touches);
    if(!_down) for (FFRTouch* touch in touches) {
        NSTimeInterval diff = touch.timestamp - _startTime;
        if(_count > 2 || diff > 3 || _count == 0) {
            _startTime = touch.timestamp;
            _startPoint = touch.location;
            _count = 0;
        }
        _down = true;
    }
    
    self.state = FFRGestureRecognizerStateBegan;
}

-(void) touchesMoved:(NSSet *)touches {
    LOGMETHOD
    //NSLog(@"touchesMoved: %@ - %@", touches, event);
}

-(void) touchesEnded:(NSSet *)touches {
    LOGMETHOD
    
    //NSLog(@"touchesEnded: %@", touches);
    
    CGPoint endPoint;
    NSTimeInterval end;
    for (FFRTouch* touch in touches) {
        endPoint = touch.location;
        end = touch.timestamp;
        _down = false;
    }
    
    CGFloat distance = [self maxDistanceBetween:_startPoint andPoint:endPoint];
    //NSLog(@"Tap diff: %f %f", distance, end - _startTime);
    if (distance < 100 && end - _startTime < 1.5) {
        _count++;
    }
    if(_count == 2) {
        [self performAction];
        _count = 0;
    }
    
    self.state = FFRGestureRecognizerStateEnded;
}

@end
