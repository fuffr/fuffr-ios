//
//  FFRGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-08.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRTouch.h"

/**
 * Type that defines constants for gesture states.
 */
typedef enum
{
	FFRGestureRecognizerStateUnknown = 0,
	FFRGestureRecognizerStateBegan = 1,
	FFRGestureRecognizerStateChanged = 2,
	FFRGestureRecognizerStateEnded = 3
}
FFRGestureRecognizerState;

@interface TargetActionPair : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

@end

/**
 Base class to hold state of a gesture recognizer
 */
@interface FFRGestureRecognizer : NSObject {
	NSMutableArray* _actionPairs;
}

/**
 State of gesture recognizer
 */
@property (nonatomic, assign) FFRGestureRecognizerState state;

/**
 The side or sides the gestures recognized monitors.
 */
@property (nonatomic, assign) FFRSide side;

/**
 The view which the recognizer is assigned to
 TODO: Used for debugging on a touch screeen, remove eventually.
 */
@property (nonatomic, weak) UIView* view;

/**
 Calculates the manhattan distance between two points (max x/y delta)
 */
-(CGFloat) maxDistanceBetween:(CGPoint)point1 andPoint:(CGPoint)point2;

/**
 Calculates the geometric distance between two points
 */
-(CGFloat) distanceBetween:(CGPoint)point1 andPoint:(CGPoint)point2;

/**
 Adds a target/action pair for when the gesture recognizer fires
 */
-(void) addTarget:(id)target action:(SEL)action;

/**
 Fires the gesture recognizer
 */
-(void) performAction;

/**
 Fires the gesture recognizer with specified object as argument
 */
-(void) performActionWithObject: (id)object;

/**
 Signals to the gesture recognizer that (nn)touches began
 */
-(void) touchesBegan:(NSSet*) touches;

/**
 Signals to the gesture recognizer that (nn)touches moved
 */
-(void) touchesMoved:(NSSet*) touches;

/**
 Signals to the gesture recognizer that (nn)touches ended
 */
-(void) touchesEnded:(NSSet*) touches;

@end
