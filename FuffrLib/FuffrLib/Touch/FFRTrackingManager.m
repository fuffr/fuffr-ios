//
//  FFRTrackingArray.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRTrackingManager.h"


NSString* const FFRTrackingBeganNotification = @"FFRTrackingBeganNotification";
NSString* const FFRTrackingMovedNotification = @"FFRTrackingMovedNotification";
NSString* const FFRTrackingPulsedNotification = @"FFRTrackingPulsedNotification";
NSString* const FFRTrackingEndedNotification = @"FFRTrackingEndedNotification";

@interface FFRTrackingManager ()

-(void) addTrackingObject: (FFRTouch*) touch;
-(void) removeTrackingObject: (FFRTouch*) touch;
-(FFRTouch*) objectInTrackedObjectsWithIdentifier: (NSUInteger)identifier;

@end

@implementation FFRTrackingManager

@synthesize trackedObjects = _trackedObjects;

-(id) init
{
	if (self = [super init])
	{
		self.trackedObjects = [[NSMutableArray alloc] init];
	}

	return self;
}

-(void) dealloc
{
	while ([_trackedObjects count])
	{
		[self removeTrackingObject: [self.trackedObjects objectAtIndex:0]];
	}
}

#pragma mark -

-(void) handleNewOrChangedTrackingObject: (FFRTouch*)touch
{
	FFRTouch* existing = [self objectInTrackedObjectsWithIdentifier: touch.identifier];

	if (existing)
	{
		existing.timestamp = touch.timestamp;
		existing.phase = touch.phase;

		if (FFRTouchPhaseEnded == existing.phase)
		{
			[self removeTrackingObject: existing];
		}
		else if (existing.location.x != touch.location.x || existing.location.y != touch.location.y)
		{
			existing.rawPoint = touch.rawPoint;
			existing.normalizedLocation = touch.normalizedLocation;
			// Updating location triggers observers.
			existing.location = touch.location;
		}
		else
		{
			//NSLog(@"! touch unchanged side: %i id: %i", (int)touch.side, (int)touch.identifier);
			[[NSNotificationCenter defaultCenter]
				postNotificationName: FFRTrackingPulsedNotification
				object: [NSSet setWithArray:_trackedObjects]
				userInfo: nil];
		}
	}
	else
	{
		//NSLog(@"! touch NEW side: %i id: %i", (int)touch.side, (int)touch.identifier);
		[self addTrackingObject: touch];
	}
}

-(void) addTrackingObject: (FFRTouch*) touch
{
// Unused key
//	[self
//		willChange: NSKeyValueChangeInsertion
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:[_trackedObjects count]]
//		forKey: @"trackedObjects"];

	[_trackedObjects insertObject: touch atIndex: [_trackedObjects count]];

// Unused key
//	[self
//		didChange :NSKeyValueChangeInsertion
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:[_trackedObjects count]]
//		forKey: @"trackedObjects"];

	[touch
		addObserver: self
		forKeyPath:@"location"
		options: NSKeyValueObservingOptionNew
		context:nil];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter]
			postNotificationName: FFRTrackingBeganNotification
			object: [NSSet setWithArray:_trackedObjects]
			userInfo:nil];
	});
}

-(void) removeTrackingObject: (FFRTouch*) touch
{
	// Get index of the touch to be removed.
	NSUInteger index = [self indexForTouch: touch.identifier];
	if (index == INT_MAX)
	{
		return;
	}

	// Unsed variable: FFRTouch* t = [_trackedObjects objectAtIndex:index];
	// Already set from touch raw data: t.phase = FFRTouchPhaseEnded;

// Unused key
//	[self
//		willChange: NSKeyValueChangeRemoval
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:index]
//		forKey: @"trackedObjects"];

	// Remove the touch.
	[_trackedObjects removeObjectAtIndex: index];

// Unused key
//	[self
//		didChange: NSKeyValueChangeRemoval
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:index]
//		forKey: @"trackedObjects"];

	// Remove the location observer for me.
	[touch removeObserver: self forKeyPath: @"location"];

	// Create a new set that includes the removed touch, so that
	// observers get the removed touch in the notified set.
	NSMutableSet* set = [NSMutableSet setWithArray:_trackedObjects];
	[set addObject: touch];

	// Notify observers.
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter]
			postNotificationName: FFRTrackingEndedNotification
			object: set
			userInfo: nil];
	});
}

#pragma mark - Tracking lookup

-(FFRTouch*) objectInTrackedObjectsWithIdentifier: (NSUInteger)identifier
{
	NSUInteger index = [self indexForTouch: identifier];
	if (index == INT_MAX)
	{
		return nil;
	}
	else
	{
		return [_trackedObjects objectAtIndex: index];
	}
}

-(NSUInteger) indexForTouch:(NSUInteger)identifier
{
	NSUInteger index = INT_MAX;
	for (int i = 0; i < [_trackedObjects count]; ++i)
	{
		FFRTouch* t = [_trackedObjects objectAtIndex:i];
		if (t.identifier == identifier)
		{
			index = i;
			break;
		}
	}

	return index;
}

#pragma mark - 

// The "location" key is changed when a touch moves.
-(void) observeValueForKeyPath:(NSString *)keyPath
	ofObject:(id)object
	change:(NSDictionary *)change
	context:(void *)context
{
	if ([keyPath compare:@"location"] == NSOrderedSame)
	{
		NSValue* value = [change objectForKey: NSKeyValueChangeNewKey];
		// Unsed variable: FFRTouch* t = object;
		// Already set from touch raw data: t.phase = FFRTouchPhaseMoved;
		[[NSNotificationCenter defaultCenter]
			postNotificationName: FFRTrackingMovedNotification
			object: [NSSet setWithArray: _trackedObjects]
			userInfo: @{@"location": value}];
	}
}

@end
