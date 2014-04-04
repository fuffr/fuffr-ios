//
//  FFRLeftRightPluggableGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2014-04-01.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRLeftRightPluggableGestureRecognizer.h"
#import "FFRTouch.h"

@implementation FFRLeftRightPluggableGestureRecognizer

- (void) findLeftRightTouch: (NSSet*)touches
{
	for (FFRTouch* touch in touches)
	{
		if (!self.touchLeft && touch.side == FFRSideLeft)
		{
			self.touchLeft = touch;
		}
		if (!self.touchRight && touch.side == FFRSideRight)
		{
			self.touchRight = touch;
		}
		if (self.touchLeft && self.touchRight)
		{
			break;
		}
	}
}

- (NSSet*) currentTouchSet
{
	if (self.touchLeft && self.touchRight)
	{
		return [NSSet setWithObjects: self.touchLeft, self.touchRight, nil];
	}
	if (self.touchLeft)
	{
		return [NSSet setWithObjects: self.touchLeft, nil];
	}
	if (self.touchRight)
	{
		return [NSSet setWithObjects: self.touchRight, nil];
	}

	// Default case is empty set.
	return [NSSet set];
}

#pragma mark - Touch handling

- (id) init
{
	self = [super init];
	if (self)
	{
		self.touchLeft = nil;
		self.touchRight = nil;
	}
    return self;
}

- (void) setGestureRecognizer: (id)recognizer
{
	//NSLog(@"setGestureRecognizer: %@", recognizer);
	self.myRecognizer = recognizer;
	[self.myRecognizer
		addTarget: self
		action: @selector(gestureRecognized:)];
}

- (void) gestureRecognized: (id)recognizer
{
	[self performActionWithObject: recognizer];
}


-(void) logTouchData
{
	FFRTouch* touch1 = self.touchLeft;
	FFRTouch* touch2 = self.touchRight;

	if (touch1 && touch2) {
	CGFloat distance = [self
			distanceBetween: touch1.location
			andPoint: touch2.location];
	NSLog(@"Dist: %f", distance);
	//NSLog(@"  pos1: %f %f", touch1.location.x, touch1.location.y);
	//NSLog(@"  pos2: %f %f", touch2.location.x, touch2.location.y);
	}
}

- (void) touchesBegan: (NSSet*)touches
{
	NSLog(@"touchesBegan: %@", self.myRecognizer);
	[self findLeftRightTouch: touches];
	[self.myRecognizer touchesBegan: [self currentTouchSet]];
}

-(void) touchesMoved:(NSSet*)touches
{
	[self logTouchData];
	[self.myRecognizer touchesMoved: [self currentTouchSet]];
}

-(void) touchesEnded: (NSSet*)touches
{
	[self.myRecognizer touchesEnded: [self currentTouchSet]];
	
	self.touchLeft = nil;
	self.touchRight = nil;
}

@end
