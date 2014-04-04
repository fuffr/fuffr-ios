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
		self.minimumTouchDistance = 200;
		self.rotationThreshold = 1.0;
		self.rotation = 0.0;
        self.touch1 = nil;
        self.touch2 = nil;
    }

    return self;
}

-(CGFloat) currentRotation
{
	return atan2(
		self.touch2.location.x - self.touch1.location.x,
		self.touch2.location.y - self.touch1.location.y);
}

-(bool) isValidRotationTouch
{
	// If are two touches we can pinch if the distance is above minumum.
	if (self.touch1 != nil && self.touch2 != nil)
	{
		CGFloat distance = [self
			distanceBetween: self.touch1.location
			andPoint: self.touch2.location];
			
		//NSLog(@"Distance in rotation: %f", distance);
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
	self.startRotation = [self currentRotation];
	self.previousRotation = self.startRotation;
	self.rotation = 0.0;
	self.state = UIGestureRecognizerStateBegan;
}

-(void) touchesMoved: (NSSet*)touches
{
    LOGMETHOD

	// Check that gesure is ongoing.
	if (! (self.state == UIGestureRecognizerStateBegan ||
		   self.state == UIGestureRecognizerStateChanged) )
	{
		return;
	}

	// Check that tracked touches are valid.
	if (self.touch1 == nil || self.touch2 == nil)
	{
		return;
	}

	// Touches must be valid.
	if (! [self isValidRotationTouch])
	{
		return;
	}
	
	CGFloat newRotation = [self currentRotation];
	if (ABS(newRotation - self.startRotation) > ((self.rotationThreshold / 180) * M_PI))
	{
		self.previousRotation = newRotation;
		self.state = UIGestureRecognizerStateChanged;
		self.rotation = newRotation - self.startRotation;
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
