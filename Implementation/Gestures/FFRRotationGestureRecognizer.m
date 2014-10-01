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

-(id) init
{
	self = [super init];

	if (self)
	{
		self.minimumTouchDistance = 50;
		self.rotationThreshold = 0.1;
		self.rotation = 0.0;
		self.touch1 = nil;
		self.touch2 = nil;
	}

	return self;
}

-(CGFloat) calculateRotation
{
	return -atan2(
		self.touch1.location.y - self.touch2.location.y,
		self.touch1.location.x - self.touch2.location.x);
}

-(bool) isValidRotationTouch: (NSSet*)touches
{
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
	if (![self isValidRotationTouch: touches])
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

		self.lowPassFilter = [FFRLowPassFilter new];
		self.previousRotation = [self calculateRotation];

		// Send gesture began notification.
		self.rotation = 0.0;
		self.state = FFRGestureRecognizerStateBegan;
		[self performAction];
	}
	else
	{
		CGFloat newRotation = [self calculateRotation];
		CGFloat deltaRotation = newRotation - self.previousRotation;
		if (ABS(deltaRotation) > ((self.rotationThreshold / 180) * M_PI))
		{
			self.previousRotation = newRotation;
			deltaRotation = MIN(deltaRotation, 0.05);
			deltaRotation = MAX(deltaRotation, -0.05);
			self.rotation += deltaRotation;
			//NSLog(@"rotation %f", self.rotation);
			self.state = FFRGestureRecognizerStateChanged;
			[self performAction];
		}
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
