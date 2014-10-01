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
		self.pinchThresholdTouchDistance = 10.0;
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

-(bool) isValidPinchTouch: (NSSet*)touches
{
	// If two touches we can pinch if the distance is above minumum.
	if (touches.count > 1)
	{
		NSArray* touchArray = [touches allObjects];
		FFRTouch* touch1 = [touchArray objectAtIndex: 0];
		FFRTouch* touch2 = [touchArray objectAtIndex: 1];
		CGFloat distance = [self
			distanceBetween: touch1.location
			andPoint: touch2.location];
			
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
}

-(void) touchesMoved: (NSSet*)touches
{
	// Must have two touches.
	if (touches.count < 2)
	{
		return;
	}

	// Touches must be valid.
	if (![self isValidPinchTouch: touches])
	{
		return;
	}

	// Initialise touches if not set.
	if (self.touch1 == nil && self.touch2 == nil)
	{
		// Save references to touches.
		NSArray* touchArray = [touches allObjects];
		self.touch1 = [touchArray objectAtIndex: 0];
		self.touch2 = [touchArray objectAtIndex: 1];
		self.startDistance = [self currentDistance];
		self.previousDistance = self.startDistance;

		// Send gesture began notification.
		self.scale = 0.0;
		self.state = FFRGestureRecognizerStateBegan;
		[self performAction];
	}

	CGFloat newDistance = [self currentDistance];
	if (ABS(newDistance - self.previousDistance) > self.pinchThresholdTouchDistance)
	{
		self.previousDistance = newDistance;
		self.state = FFRGestureRecognizerStateChanged;
		self.scale = newDistance / self.startDistance;
		[self performAction];
	}
}

-(void) touchesEnded: (NSSet*)touches
{
	if (self.touch1 != nil && self.touch1 != nil)
	{
		self.state = FFRGestureRecognizerStateEnded;
		[self performAction];
	}

	self.touch1 = nil;
	self.touch2 = nil;
}

@end
