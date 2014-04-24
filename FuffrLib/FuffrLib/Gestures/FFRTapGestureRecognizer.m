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

#pragma mark - touch debug

-(void) touchesBegan:(NSSet*)touches
{
    LOGMETHOD

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
    LOGMETHOD

    //NSLog(@"touchesEnded: %@", self);

	if (self.touch)
	{
        CGPoint endPoint = self.touch.location;
        NSTimeInterval endTime = self.touch.timestamp;
    	CGFloat distance = [self maxDistanceBetween: self.startPoint andPoint: endPoint];
    	//NSLog(@"Tap diff time: %f dist: %f", endTime - self.startTime, distance);
    	if (distance < 50.0 && endTime - self.startTime < 0.5)
		{
        	[self performAction];
		}
    	self.touch = nil;
	}
}

@end
