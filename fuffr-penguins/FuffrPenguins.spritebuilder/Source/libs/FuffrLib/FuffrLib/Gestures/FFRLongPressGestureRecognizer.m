//
//  FFRLongPressGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-11.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRLongPressGestureRecognizer.h"
#import "FFRTouch.h"

@implementation FFRLongPressGestureRecognizer

- (id) init
{
	self = [super init];

	if (self)
	{
		self.touch = nil;
		self.maximumDistance = 50.0;
		self.minimumDuration = 1.0;
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
		self.startPoint = self.touch.location;
		self.timer = [NSTimer
			scheduledTimerWithTimeInterval: self.minimumDuration
			target: self
			selector: @selector(timerFired:)
			userInfo: nil
			repeats: NO];
	}
}

-(void) touchesMoved:(NSSet *)touches
{
}

-(void) touchesEnded:(NSSet *)touches
{
	if (self.touch && self.touch.phase == FFRTouchPhaseEnded)
	{
		self.touch = nil;
	}
}

-(void) timerFired:(id)sender
{
	if (self.touch)
	{
		CGPoint endPoint = self.touch.location;
		CGFloat distance = [self maxDistanceBetween: self.startPoint andPoint: endPoint];
		//NSLog(@"LongPress diff dist: %f", distance);
		if (distance < self.maximumDistance)
		{
			self.state = FFRGestureRecognizerStateEnded;
			[self performAction];
		}
		self.touch = nil;
		self.timer = nil;
	}
}

@end
