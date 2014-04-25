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

- (id) init
{
	self = [super init];

	if (self)
	{
		self.touch = nil;
		self.touchCount = 0;
		self.maximumDistance = 100.0;
		self.maximumDuration = 1.5;
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

		if (self.touchCount == 0)
		{
			self.startTime = self.touch.timestamp;
			self.startPoint = self.touch.location;
		}

		self.touchCount ++;
	}
}

-(void) touchesMoved:(NSSet *)touches
{
}

-(void) touchesEnded:(NSSet *)touches
{
	if (self.touch && self.touch.phase == FFRTouchPhaseEnded)
	{
		if (self.touchCount == 2)
		{
			CGPoint endPoint = self.touch.location;
			NSTimeInterval endTime = self.touch.timestamp;
			CGFloat distance = [self maxDistanceBetween: self.startPoint andPoint: endPoint];
			if (distance < self.maximumDistance &&
				(endTime - self.startTime) < self.maximumDuration)
			{
				self.state = UIGestureRecognizerStateEnded;
				[self performAction];
			}
			_touchCount = 0;
		}
		_touch = nil;
	}
}

@end
