//
//  FFRTapGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-31.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRTapGestureRecognizer.h"
#import "FFRTouch.h"

@implementation FFRTapGestureRecognizer

- (id) init
{
	self = [super init];

	if (self)
	{
		self.touch = nil;
		self.maximumDistance = 50.0;
		self.maximumDuration = 0.5;
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
}

-(void) touchesEnded:(NSSet *)touches
{
	//NSLog(@"touchesEnded: %@", self);

	if (self.touch && self.touch.phase == FFRTouchPhaseEnded)
	{
		CGPoint endPoint = self.touch.location;
		NSTimeInterval endTime = self.touch.timestamp;
		CGFloat distance = [self maxDistanceBetween: self.startPoint andPoint: endPoint];
		//NSLog(@"Tap diff time: %f dist: %f", endTime - self.startTime, distance);
		if (distance < self.maximumDistance &&
			(endTime - self.startTime) < self.maximumDuration)
		{
			self.state = UIGestureRecognizerStateEnded;
			[self performAction];
		}
		self.touch = nil;
	}
}

@end
