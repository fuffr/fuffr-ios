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

/*
static void logTouches(NSString* label, NSSet* touches)
{
	int down = 0, up = 0, moved = 0, total = 0;
	for (FFRTouch* t in touches)
	{
		if (t.phase == FFRTouchPhaseBegan) down++;
		if (t.phase == FFRTouchPhaseEnded) up++;
		if (t.phase == FFRTouchPhaseMoved) moved++;
		total++;
	}
	NSLog(@"%@ DOWN: %i UP: %i MOVED: %i TOTAL: %i", label, down, up, moved, total);
}
*/

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
		self.touchRemoveTimeout = 0.20;
		_timer = [NSTimer
			scheduledTimerWithTimeInterval: self.touchRemoveTimeout / 3.0
			target: self
			selector: @selector(timerPruneTouches:)
			userInfo: nil
			repeats: YES];
	}

	return self;
}

-(void) dealloc
{
	[self shutDown];
}

-(void) shutDown
{
	if (_timer)
	{
		[_timer invalidate];
		_timer = nil;
	}
	if (_trackedObjects)
	{
		[self clearAllTouches];
		_trackedObjects = nil;
	}
}

-(void) clearAllTouches
{
	while ([_trackedObjects count])
	{
		[self removeTrackingObject: [self.trackedObjects objectAtIndex:0]];
	}
}

-(void) timerPruneTouches:(id) sender
{
	if (!_trackedObjects) { return; }
	
	//NSLog(@"timerPruneTouches queue: %s", dispatch_queue_get_label(dispatch_get_current_queue()));
	dispatch_async(self.backgroundQueue,
	^{
		NSMutableArray* removedTouches = [NSMutableArray array];
		NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];

		for (int i = 0; i < [_trackedObjects count]; ++i)
		{
			FFRTouch* t = [_trackedObjects objectAtIndex:i];
			if (now - t.timestamp >= self.touchRemoveTimeout)
			{
				[removedTouches addObject: t];
			}
		}

		for (FFRTouch* t in removedTouches)
		{
			if (t.phase != FFRTouchPhaseEnded) {
			//NSLog(@"***Pruning id: %d, side: %d, ntouches: %d, rawcoord: %@", (int)t.identifier, t.side, (int)[_trackedObjects count], NSStringFromCGPoint(t.rawPoint));
			[self removeTrackingObject: t];
			}
		}
	});
}

-(void) handleNewOrChangedTrackingObject: (FFRTouch*)touch
{
	FFRTouch* existing = [self objectInTrackedObjectsWithIdentifier: touch.identifier];

	if (existing)
	{
		existing.timestamp = touch.timestamp;
		// DO NOT SET YET. existing.phase = touch.phase;

		if (FFRTouchPhaseEnded == touch.phase)
		{
			//NSLog(@"***Removing touch by FLAG: %i", (int)touch.identifier);
			[self removeTrackingObject: existing];
		}
		else if (existing.location.x != touch.location.x || existing.location.y != touch.location.y)
		{
			existing.rawPoint = touch.rawPoint;
			existing.normalizedLocation = touch.normalizedLocation;
			// Updating location triggers observers.
			existing.location = touch.location;

			NSSet* touches = [NSSet setWithArray: _trackedObjects];

			//logTouches(@"FFRTracking moved", touches);

			dispatch_async(dispatch_get_main_queue(),
			^{
				//NSLog(@"Touches moved dispatch on main");
				existing.phase = FFRTouchPhaseMoved;
				[[NSNotificationCenter defaultCenter]
					postNotificationName: FFRTrackingMovedNotification
					object: touches
					userInfo: nil];
			});
		}
		else
		{
			//NSLog(@"! touch unchanged side: %i id: %i", (int)touch.side, (int)touch.identifier);
			
			NSSet* touches = [NSSet setWithArray: _trackedObjects];
			dispatch_async(dispatch_get_main_queue(),
			^{
				[[NSNotificationCenter defaultCenter]
					postNotificationName: FFRTrackingPulsedNotification
					object: touches
					userInfo: nil];
			});
		}
	}
	else
	{
		// Only add touches that have phase began or moved (that is, not ended).
		if (FFRTouchPhaseEnded != touch.phase)
		{
			//if (FFRTouchPhaseBegan != touch.phase) NSLog(@"***New touch id: %i, side: %i, phase: %i", (int)touch.identifier, (int)touch.side, (int)touch.phase);

			[self addTrackingObject: touch];
		}
	}
}

// For debugging.
//static int NumberOfActiveTouches = 0;

-(void) addTrackingObject: (FFRTouch*) touch
{
//NSLog(@"addTrackingObject queue: %s", dispatch_queue_get_label(dispatch_get_current_queue()));
// Unused key
//	[self
//		willChange: NSKeyValueChangeInsertion
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:[_trackedObjects count]]
//		forKey: @"trackedObjects"];

	// Set touch phase to began explicitly, in case the touch down event
	// never was recieved (this this case the phase will be moved for a
	// touch that is not in the list).
	touch.phase = FFRTouchPhaseBegan;
	[_trackedObjects insertObject: touch atIndex: [_trackedObjects count]];

// Unused key
//	[self
//		didChange :NSKeyValueChangeInsertion
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:[_trackedObjects count]]
//		forKey: @"trackedObjects"];

//	[touch
//		addObserver: self
//		forKeyPath:@"location"
//		options: NSKeyValueObservingOptionNew
//		context:nil];

	NSSet* touches = [NSSet setWithObject: touch];

	//logTouches(@"FFRTracking began", touches);

	// Notify tracking observers.
	dispatch_async(dispatch_get_main_queue(),
	^{
		// Set touch phase to began again on the main queue, to prevent
		// overwrite by moved events (moved also set on main queue).
		touch.phase = FFRTouchPhaseBegan;
		[[NSNotificationCenter defaultCenter]
			postNotificationName: FFRTrackingBeganNotification
			object: touches
			userInfo:nil];
	});

	//++NumberOfActiveTouches;
	//NSLog(@"FFRTrackingManager added touch: %@ active touches: %i", touch, NumberOfActiveTouches);
}

-(void) removeTrackingObject: (FFRTouch*) touch
{
//NSLog(@"removeTrackingObject queue: %s", dispatch_queue_get_label(dispatch_get_current_queue()));
	// Get index of the touch to be removed.
	NSUInteger index = [self indexForTouch: touch.identifier];
	if (index == INT_MAX)
	{
		NSLog(@"Did not find touch to remove");
		return;
	}

	//NSLog(@"Found touch to remove id: %d ntouches: %d", (int)touch.identifier, (int)[_trackedObjects count]);

// Unused key
//	[self
//		willChange: NSKeyValueChangeRemoval
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:index]
//		forKey: @"trackedObjects"];

	// Remove the touch.
	[_trackedObjects removeObjectAtIndex: index];
	
	//NSLog(@"Removed touch id: %d ntouches: %d", (int)touch.identifier, (int)[_trackedObjects count]);

// Unused key
//	[self
//		didChange: NSKeyValueChangeRemoval
//		valuesAtIndexes: [NSIndexSet indexSetWithIndex:index]
//		forKey: @"trackedObjects"];

	// Remove the location observer for me.
//	[touch removeObserver: self forKeyPath: @"location"];

	// Create a new set that includes the removed touch, so that
	// observers get the removed touch in the notified set.
	//NSMutableSet* set = [NSMutableSet setWithArray:_trackedObjects];
	//[set addObject: touch];

	NSSet* touches = [NSSet setWithObject: touch];

	// Notify tracking observers.
	dispatch_async(dispatch_get_main_queue(),
	^{
		touch.phase = FFRTouchPhaseEnded;
		//logTouches(@"FFRTracking ended", touches);
		[[NSNotificationCenter defaultCenter]
			postNotificationName: FFRTrackingEndedNotification
			object: touches
			userInfo: nil];
	});

	//--NumberOfActiveTouches;
	//NSLog(@"FFRTrackingManager removed touch: %@ active touches: %i", touch, NumberOfActiveTouches);
}

#pragma mark - Tracking lookup

-(FFRTouch*) objectInTrackedObjectsWithIdentifier: (NSUInteger)identifier
{
	@try
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
	@catch (NSException* e)
	{
		NSLog(@"Exception in FFRTrackingManager objectInTrackedObjectsWithIdentifier");
		return nil;
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

/*
// The "location" key is updated when a touch moves.
-(void) observeValueForKeyPath:(NSString *)keyPath
	ofObject:(id)object
	change:(NSDictionary *)change
	context:(void *)context
{
	if ([keyPath compare:@"location"] == NSOrderedSame)
	{
	
		logTouches(@"FFRTracking moved", [NSSet setWithArray:_trackedObjects]);

		NSValue* value = [change objectForKey: NSKeyValueChangeNewKey];
		// Unsed variable: FFRTouch* t = object;
		// Already set from touch raw data: t.phase = FFRTouchPhaseMoved;
		dispatch_async(dispatch_get_main_queue(),
		^{
			[[NSNotificationCenter defaultCenter]
				postNotificationName: FFRTrackingMovedNotification
				object: [NSSet setWithArray: _trackedObjects]
				userInfo: @{@"location": value}];
		});
	}
}
*/

@end
