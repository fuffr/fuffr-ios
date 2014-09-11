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

- (id) init
{
	self = [super init];

	if (self)
	{
		self.touch = nil;
		self.minimumDistance = 200.0;
		self.maximumDuration = 1.0;
	}

	return self;
}

-(void) touchesBegan:(NSSet*)touches
{
	if (self.touch == nil)
	{
		// Start tracking the first touch.
		NSArray* touchArray = [touches allObjects];
		self.touch = [touchArray objectAtIndex: 0];
		self.startTime = self.touch.timestamp;
		self.startPoint = self.touch.location;
	}
}

-(void) touchesMoved:(NSSet *)touches
{
	if (!self.touch)
	{
		return;
	}

	NSTimeInterval duration  = self.touch.timestamp - self.startTime;
	if (!(duration < self.maximumDuration))
	{
		// Timed out.
		self.touch = nil;
		return;
	}

	CGPoint point = self.touch.location;
	CGFloat distanceX = ABS(self.startPoint.x - point.x);
	CGFloat distanceY = ABS(self.startPoint.y - point.y);
	BOOL gestureHasTriggered = NO;

	if (self.direction == FFRSwipeGestureRecognizerDirectionLeft)
	{
		gestureHasTriggered =
			distanceX > self.minimumDistance &&
			distanceX > distanceY &&
			self.startPoint.x > point.x;
	}
	else if (self.direction == FFRSwipeGestureRecognizerDirectionRight)
	{
		gestureHasTriggered =
			distanceX > self.minimumDistance &&
			distanceX > distanceY &&
			self.startPoint.x < point.x;
	}
	else if (self.direction == FFRSwipeGestureRecognizerDirectionUp)
	{
		//NSLog(@"UP distX %f distY: %f", distanceX, distanceY);
		gestureHasTriggered =
			distanceY > self.minimumDistance &&
			distanceX < distanceY &&
			self.startPoint.y > point.x;
	}
	else if (self.direction == FFRSwipeGestureRecognizerDirectionDown)
	{
		//NSLog(@"DOWN distX %f distY: %f", distanceX, distanceY);
		gestureHasTriggered =
			distanceY > self.minimumDistance &&
			distanceX < distanceY &&
			self.startPoint.y < point.x;
	}

	if (gestureHasTriggered)
	{
		self.state = FFRGestureRecognizerStateEnded;
		[self performAction];
		self.touch = nil;
	}
}

-(void) touchesEnded:(NSSet *)touches
{
	self.touch = nil;
}

@end
