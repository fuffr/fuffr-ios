//
//  FFRGestureManager.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-21.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureManager.h"
#import "FFRCaseHandler.h"
#import "FFRGestureRecognizer.h"

@implementation FFRGestureManager

-(id) init {
    if (self = [super init]) {
        _recognizers = [NSMutableArray array];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackingBegan:) name:FFRTrackingBeganNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackingMoved:) name:FFRTrackingBeganNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackingEnded:) name:FFRTrackingBeganNotification object:nil];
    }

    return self;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+(instancetype) sharedManager {
    static dispatch_once_t pred;
    static FFRGestureManager *client = nil;

    dispatch_once(&pred, ^{ client = [[self alloc] init]; });
    return client;
}

-(void) addGestureRecognizer:(FFRGestureRecognizer*)recognizer {
    [_recognizers addObject:recognizer];
}

-(void) removeGestureRecognizer:(FFRGestureRecognizer*)recognizer {
    [_recognizers removeObject:recognizer];
}

#pragma mark - notifications

-(void) trackingBegan:(NSNotification*) data {
    LOGMETHOD
    
    NSSet* tracking = data.object;
    // pass on to any recognizer with views that the point is in

    for (FFRGestureRecognizer* recognizer in _recognizers) {
        NSMutableSet* set = [NSMutableSet set];
        for (FFRTouch* track in tracking) {
            if (CGRectContainsPoint(recognizer.view.frame, track.location)) {
                [set addObject:track];
            }
        }

        [recognizer touchesBegan:set];
    }
}

-(void) trackingMoved:(NSNotification*) data {
    LOGMETHOD

    NSSet* tracking = data.object;

    // pass on to any recognizer with views that the point is in and is in started state
    // detect if moved outside of view, send cancelled if in started state
    for (FFRGestureRecognizer* recognizer in _recognizers) {
        if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged || recognizer.state == UIGestureRecognizerStatePossible) {
            BOOL needsCancel = FALSE;
            for (FFRTouch* track in tracking) {
                if (!CGRectContainsPoint(recognizer.view.frame, track.location)) {
                    needsCancel = TRUE;
                    break;
                }
            }

            if (needsCancel) {
                for (FFRTouch* track in tracking) {
                    track.phase = UITouchPhaseCancelled;
                }

                [recognizer touchesCancelled:tracking];
            }
            else {
                [recognizer touchesMoved:tracking];
            }
        }
    }
}

-(void) trackingEnded:(NSNotification*) data {
    LOGMETHOD

    NSSet* tracking = data.object;

    // pass on to any recognizer with views that the point is in and is in started state
    for (FFRGestureRecognizer* recognizer in _recognizers) {
        if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {

            for (FFRTouch* track in tracking) {
                if (CGRectContainsPoint(recognizer.view.frame, track.location)) {
                    [recognizer touchesEnded:tracking];
                }
            }
        }
    }
}

@end
