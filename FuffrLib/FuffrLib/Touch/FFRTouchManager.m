//
//  FFRTouchManager.m
//  This is a high-level touch and connection mananger for
//  the FuffrLib.
//
//  Created by Mikael Kindborg on 07/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRTouchManager.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

/**
 * Class used internally by the touch manager to track
 * touch observers. These observers are notified when touch
 * events occur.
 */
@interface FFRTouchEventObserver : NSObject

// Reference to the observer.
@property (nonatomic, weak) id object;

// Selectors.
@property SEL beganSelector;
@property SEL movedSelector;
@property SEL endedSelector;

// Sides (can be combined with bitwise-or).
@property FFRCaseSide side;

@end

@implementation FFRTouchEventObserver
@end

@implementation FFRTouchManager

// Helper function.
static BOOL stringContains(NSString* string, NSString* substring)
{
	return [string
		rangeOfString: substring
		options:NSCaseInsensitiveSearch].location != NSNotFound;
}

// Helper function.
static NSSet* filterTouchesBySide(NSSet* touches, FFRCaseSide side)
{
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			return side & ((FFRTouch*)obj).side;
    	}];
}

// Singleton instance.
static FFRTouchManager* sharedInstance = NULL;

// Public class method.

+ (FFRTouchManager*) sharedManager
{
	if (NULL == sharedInstance)
	{
		sharedInstance = [FFRTouchManager new];
	}

	return sharedInstance;
}

// Public instance methods.

- (void) addTouchObserver: (id)object
	touchBegan: (SEL)touchBeganSelector
	touchMoved: (SEL)touchMovedSelector
	touchEnded: (SEL)touchEndedSelector
	side: (FFRCaseSide)side
{
	FFRTouchEventObserver* observer = [FFRTouchEventObserver new];
	observer.object = object;
	observer.beganSelector = touchBeganSelector;
	observer.movedSelector = touchMovedSelector;
	observer.endedSelector = touchEndedSelector;
	observer.side = side;
	[self.touchObservers addObject: observer];
}

- (void) removeTouchObserver: (id)object
{
	[self.touchObservers removeObject: object];
}

// Internal instance methods.

- (id) init
{
	self.touchObservers = [NSMutableArray array];
	[self registerTouchMethods];
	return self;
}

- (BOOL) connectToSensorCaseNotifying: (id)object
	onSuccess: (SEL)successSelector
	onError: (SEL)errorSelector;
{
	if (self.scanIsOngoing)
	{
		return NO;
	}

	self.connectedNotificatonTarget = object;
	self.connectedSuccessSelector = successSelector;

	[self startScan];

	return YES;
}

- (void) startScan
{
	NSLog(@"startScan");

	self.scanIsOngoing = YES;

    [[FFRBLEManager sharedManager]
		addObserver:self
		forKeyPath:@"discoveredDevices"
		options:
			NSKeyValueChangeInsertion |
			NSKeyValueChangeRemoval |
			NSKeyValueChangeReplacement
		context:nil];

    [[FFRBLEManager sharedManager] startScan: YES];
}

- (void) stopScan
{
	NSLog(@"stopScan");

    [[FFRBLEManager sharedManager] stopScan];
    [[FFRBLEManager sharedManager]
		removeObserver:self
		forKeyPath:@"discoveredDevices"];

	self.scanIsOngoing = NO;
}

- (void) observeValueForKeyPath: (NSString*)keyPath
	ofObject: (id)object
	change: (NSDictionary*)change
	context: (void*)context
{
    if ([keyPath compare:@"discoveredDevices"] == NSOrderedSame)
	{
        dispatch_async(dispatch_get_main_queue(),
		^{
            // Found device.
			FFRBLEManager* manager = [FFRBLEManager sharedManager];
			for (int i = 0; i < manager.discoveredDevices.count; ++i)
			{
        		CBPeripheral* p = [manager.discoveredDevices objectAtIndex:i];
				NSLog(@"Found device: %@", p);
				if (stringContains(p.name, @"Neonode") ||
					stringContains(p.name, @"Fuffr"))
				{
					[self stopScan];
					[[FFRBLEManager sharedManager] connectPeripheral: p];
					[self initSensorCase];
					[self notifyConnected: YES];
					break;
				}
    		}
        });
    }
}

- (void) initSensorCase
{
    FFRBLEManager* BLEManager = [FFRBLEManager sharedManager];

    if (![BLEManager.handler isKindOfClass: [FFRCaseHandler class]])
	{
        BLEManager.handler = [FFRCaseHandler new];
		if ([BLEManager.connectedDevices count])
		{
			[BLEManager.handler loadPeripheral:
				[BLEManager.connectedDevices firstObject]];
		}
    }

    __weak FFRBLEManager* manager = BLEManager;
    [BLEManager
		addMonitoredService: FFRCaseSensorServiceUuid
		onDiscovery: ^(CBService* service, CBPeripheral* hostPeripheral)
		{
        	[manager.handler loadPeripheral:hostPeripheral];
    	}
	];
}

- (void) notifyConnected: (BOOL)success
{
	[self.connectedNotificatonTarget
		performSelector: self.connectedSuccessSelector];

	self.connectedNotificatonTarget = nil;
	self.connectedSuccessSelector = nil;
}

- (void) registerTouchMethods
{
    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleTouchBeganNotification:)
		name: FFRTrackingBeganNotification
		object: nil];
    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleTouchMovedNotification:)
		name: FFRTrackingMovedNotification
		object: nil];
    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleTouchEndedNotification:)
		name: FFRTrackingEndedNotification
		object: nil];
}

- (void) handleTouchBeganNotification: (NSNotification*)data
{
    NSSet* touches = data.object;

    for (FFRTouchEventObserver* observer in self.touchObservers)
	{
		if (observer.beganSelector)
		{
			NSSet* observedTouches = filterTouchesBySide(touches, observer.side);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.beganSelector
					withObject: observedTouches];
			}
		}
	}
}

- (void) handleTouchMovedNotification: (NSNotification*)data
{
    NSSet* touches = data.object;

    for (FFRTouchEventObserver* observer in self.touchObservers)
	{
		if (observer.movedSelector)
		{
			NSSet* observedTouches = filterTouchesBySide(touches, observer.side);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.movedSelector
					withObject: observedTouches];
			}
		}
	}
}

- (void) handleTouchEndedNotification: (NSNotification*)data
{
    NSSet* touches = data.object;

    for (FFRTouchEventObserver* observer in self.touchObservers)
	{
		if (observer.endedSelector)
		{
			NSSet* observedTouches = filterTouchesBySide(touches, observer.side);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.endedSelector
					withObject: observedTouches];
			}
		}
	}
}

#pragma clang diagnostic pop

@end
