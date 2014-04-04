//
//  FFRRotationGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-12.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRRotationGestureRecognizer.h"
#import "FFRTouch.h"


@implementation FFRRotationGestureRecognizer


-(void) setRotation:(CGFloat)rotation {
    _rotation = rotation;
}


#pragma mark - Touch handling

-(void) touchesBegan:(NSSet*)touches {
    LOGMETHOD

    self.state = ([touches count] >= 2) ? UIGestureRecognizerStateBegan : UIGestureRecognizerStatePossible;
    _unlocked = FALSE;

    if ([touches count] <= 1) {
        _rotationLock = 0;
    }
}

-(void) touchesMoved:(NSSet *)touches {
    LOGMETHOD

	if ([touches count] <= 1) {
        return;
    }

    if (self.state == UIGestureRecognizerStateBegan) {
        FFRTouch* t1 = [[touches allObjects] objectAtIndex:0];
        FFRTouch* t2 = [[touches allObjects] objectAtIndex:1];

        CGFloat rotation = atan2(t2.location.x - t1.location.x, t2.location.y - t1.location.y);
        _rotationLock = rotation;
        self.state = UIGestureRecognizerStateChanged;
    }
    else if (self.state == UIGestureRecognizerStateChanged) {
        FFRTouch* t1 = [[touches allObjects] objectAtIndex:0];
        FFRTouch* t2 = [[touches allObjects] objectAtIndex:1];
        CGFloat rotation = atan2(t2.location.x - t1.location.x, t2.location.y - t1.location.y);

        if (ABS(rotation - _rotationLock) > 10.0 / 180 * M_PI) {
            _unlocked = TRUE;
        }

        _rotation = rotation - _rotationLock;

        if (_unlocked) {
            [self performAction];
        }
    }
}

-(void) touchesEnded:(NSSet *)touches {
    LOGMETHOD

    self.state = ([touches count] >= 2) ? UIGestureRecognizerStateChanged : UIGestureRecognizerStateEnded;
}

-(void) touchesCancelled:(NSSet *)touches {
    LOGMETHOD

    self.state = ([touches count] >= 2) ? UIGestureRecognizerStateChanged : UIGestureRecognizerStateCancelled;
}

@end
