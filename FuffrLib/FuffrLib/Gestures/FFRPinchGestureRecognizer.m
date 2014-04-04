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

-(id) init
{
	self = [super init];

    if (self)
	{
		self.minimumTouchDistance = 50;
		self.pinchThresholdTouchDistance = 1.0;
		self.scale = 0.0;
        self.touch1 = nil;
        self.touch2 = nil;
    }

    return self;
}

-(CGFloat) currentDistance
{
	return [self
		distanceBetween: self.touch1.location
		andPoint: self.touch2.location];
}

-(bool) isValidPinchTouch
{
	// If are two touches we can pinch if the distance is above minumum.
	if (self.touch1 != nil && self.touch2 != nil)
	{
		CGFloat distance = [self
			distanceBetween: self.touch1.location
			andPoint: self.touch2.location];
			
		//NSLog(@"Distance in pinch: %f", distance);
		if (distance > self.minimumTouchDistance)
		{
			return true;
		}
	}

	return false;
}

#pragma mark - Touch handling

-(void) touchesBegan: (NSSet*)touches
{
    LOGMETHOD

	// Tracked touches must be nil.
	if (! (self.touch1 == nil && self.touch2 == nil) )
	{
		return;
	}

	// Number of touches must be valid.
	if (touches.count < 2)
	{
		return;
	}

	// Save references to touches.
	NSArray* touchArray = [touches allObjects];
	self.touch1 = [touchArray objectAtIndex: 0];
	self.touch2 = [touchArray objectAtIndex: 1];
	self.startDistance = [self currentDistance];
	self.previousDistance = self.startDistance;
	self.scale = 0.0;
	self.state = UIGestureRecognizerStateBegan;
}

-(void) touchesMoved: (NSSet*)touches
{
    LOGMETHOD

	// Check that tracked touches are valid.
	if (self.touch1 == nil || self.touch2 == nil)
	{
		return;
	}

	// Touches must be valid.
	if (! [self isValidPinchTouch])
	{
		return;
	}
	
	CGFloat newDistance = [self currentDistance];
	if (ABS(newDistance - self.previousDistance) > self.pinchThresholdTouchDistance)
	{
		self.previousDistance = newDistance;
		self.state = UIGestureRecognizerStateChanged;
		self.scale = newDistance / self.startDistance;
		[self performAction];
	}
}

-(void) touchesEnded: (NSSet*)touches
{
    LOGMETHOD

	if (self.touch1 != nil && self.touch1 != nil)
	{
		self.state = UIGestureRecognizerStateEnded;
		[self performAction];
	}

	self.touch1 = nil;
	self.touch2 = nil;
}

@end
