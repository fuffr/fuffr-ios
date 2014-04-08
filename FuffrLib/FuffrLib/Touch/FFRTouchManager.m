//
//  FFRTouchManager.m
//  This is a high-level touch and connection mananger for
//  the FuffrLib.
//
//  Created by Fuffr on 07/03/14.
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
@property FFRSide side;

@end

@implementation FFRTouchEventObserver
@end

@interface FFRTouchManager ()

/**
 * The device with strongest signal strength, used during scanning
 * to determine closest device.
 */
@property CBPeripheral* deviceWithMaxRSSI;

/**
 * The device we are connected to. Used when reconnecting.
 */
@property CBPeripheral* activeDevice;

/**
 * Connection success and error blocks.
 * Invoked when connected to Fuffr.
 */
@property (nonatomic, copy) void(^connectSuccessBlock)();
@property (nonatomic, copy) void(^connectErrorBlock)();

/** List of touch observers. */
@property NSMutableArray* touchObservers;

/** List of gesture recognizers. */
@property NSMutableArray* gestureRecognizers;

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
/* Unused
static NSSet* filterTouchesBySide(NSSet* touches, FFRSide side)
{
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			return side & ((FFRTouch*)obj).side;
    	}];
}
*/

// Helper function.
static NSSet* filterTouchesBySideAndPhase(NSSet* touches, FFRSide side, UITouchPhase phase)
{
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			return (side & ((FFRTouch*)obj).side) && (phase == ((FFRTouch*)obj).phase);
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

- (void) connectToFuffrOnSuccess: (void(^)())successBlock
	onError: (void(^)())errorBlock
{
	self.connectSuccessBlock = successBlock;
	self.connectErrorBlock = errorBlock;

	// Scan is started automatically by FFRBLEManager.
	//[self startScan];
}

- (void) disconnectFuffr
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	self.activeDevice = [bleManager.connectedDevices firstObject];
	if (self.activeDevice != nil)
	{
		[bleManager disconnectPeripheral: self.activeDevice];
	}
}

- (void) reconnectFuffr
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	if (self.activeDevice != nil)
	{
		[bleManager connectPeripheral: self.activeDevice];
	}
}

- (void) addTouchObserver: (id)object
	touchBegan: (SEL)touchBeganSelector
	touchMoved: (SEL)touchMovedSelector
	touchEnded: (SEL)touchEndedSelector
	side: (FFRSide)side
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

-(void) addGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer
{
	[self.gestureRecognizers addObject: gestureRecognizer];
}

-(void) removeGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer
{
	[self.gestureRecognizers removeObject: gestureRecognizer];
}

// Internal instance methods.

- (id) init
{
	self.connectSuccessBlock = nil;
	self.connectErrorBlock = nil;
	self.touchObservers = [NSMutableArray array];
	self.gestureRecognizers = [NSMutableArray array];
	self.deviceWithMaxRSSI = nil;
	self.activeDevice = nil;
	[self registerTouchMethods];
	[self registerPeripheralDiscoverer];
	return self;
}

// TODO: Delete.
- (void) startScan
{
	NSLog(@"startScan");

	// Callback is used instread of KVO.
    /*[[FFRBLEManager sharedManager]
		addObserver:self
		forKeyPath:@"discoveredDevices"
		options:
			NSKeyValueChangeInsertion |
			NSKeyValueChangeRemoval |
			NSKeyValueChangeReplacement
		context:nil];*/

	// Not needed?
    //[bleManager startScan: YES];
}

// TODO: Delete.
- (void) stopScan
{
	NSLog(@"stopScan");

    /* [[FFRBLEManager sharedManager]
		removeObserver:self
		forKeyPath:@"discoveredDevices"]; */
    [[FFRBLEManager sharedManager] stopScan];
}

-(void) connectToDeviceWithMaxRSSI
{
	NSLog(@"connectToDeviceWithMaxRSSI");
	[[FFRBLEManager sharedManager] connectPeripheral: self.deviceWithMaxRSSI];
	[self initFuffr];
}

- (void) registerPeripheralDiscoverer
{
	__weak FFRTouchManager* me = self;

	// Set discovery callback.
    FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	bleManager.onPeripheralDiscovery = ^(CBPeripheral* p)
	{
		NSLog(@"Found peripheral: %@", p);

		if (stringContains(p.name, @"Fuffr") ||
			stringContains(p.name, @"Neonode"))
		{
			if (nil == me.deviceWithMaxRSSI)
			{
				NSLog(@"start timer for connectToDeviceWithMaxRSSI");
				me.deviceWithMaxRSSI = p;
				[NSTimer
					scheduledTimerWithTimeInterval: 2.0
					target: me
					selector:@selector(connectToDeviceWithMaxRSSI)
					userInfo:nil
					repeats:NO
				];
			}
			else
			{
				NSNumber* rssiMax = me.deviceWithMaxRSSI.discoveryRSSI;
				NSNumber* rssiNew = p.discoveryRSSI;
				if (rssiNew.intValue > rssiMax.intValue)
				{
					NSLog(@"Found device with stronger RSSI");
					me.deviceWithMaxRSSI = p;
				}
			}
		}
	};
}


// Callback used instead of KVO.
/*
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
				if (self.scanIsOngoing &&
					(stringContains(p.name, @"Fuffr") ||
					stringContains(p.name, @"Neonode")))
				{
					// connectPeripheral stops scan.
					[[FFRBLEManager sharedManager] connectPeripheral: p];

					[self initFuffr];

					break;
				}
    		}
        });
    }
}
*/

// Create BLE manager handler object and add a callback
// that enables Fuffr when characteristics for the service
// are discovered.
// TODO: Why not rather do this in a more encapsulated way?
// Perhaps belongs well here since objects are created and
// connected, but the approach feels ad hoc, the two tasks
// are not really related? Or?
- (void) initFuffr
{
    FFRBLEManager* bleManager = [FFRBLEManager sharedManager];

    if (![bleManager.handler isKindOfClass: [FFRCaseHandler class]])
	{
        bleManager.handler = [FFRCaseHandler new];
		/*if ([bleManager.connectedDevices count] > 0)
		{
			NSLog(@"initFuffr loadPeripheral");
			[bleManager.handler loadPeripheral:
				[bleManager.connectedDevices firstObject]];
			[self notifyConnected: YES];

			// We hace connected, return at this point.
			return;
		}*/
    }

	// If we have not connected, proceed using the addMonitoredService
	// mechanism...

    __weak FFRTouchManager* me = self;
	__weak FFRBLEManager* manager = bleManager;
	// Starts service discovery.
    [bleManager
		addMonitoredService: FFRCaseSensorServiceUuid
		onDiscovery: ^(CBService* service, CBPeripheral* hostPeripheral)
		{
			NSLog(@"initFuffr loadPeripheral monitored service");
        	[manager.handler loadPeripheral:hostPeripheral];
			[me notifyConnected: YES];
    	}
	];
}

- (void) notifyConnected: (BOOL)success
{
	if (success)
	{
		self.connectSuccessBlock();
	}
	else
	{
		self.connectErrorBlock();
	}
}

- (void) enableSides:(FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	[bleManager.handler enableSides: sides touchesPerSide: numberOfTouches];
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

	//NSLog(@"touchBegan count: %i", touches.count);

	// Notify touch observers.
    for (FFRTouchEventObserver* observer in self.touchObservers)
	{
		if (observer.beganSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.side,
				UITouchPhaseBegan);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.beganSelector
					withObject: observedTouches];
			}
		}
	}

	// Notify gesture recognizers.
    for (FFRGestureRecognizer* recognizer in self.gestureRecognizers)
	{
		NSSet* observedTouches = filterTouchesBySideAndPhase(
			touches,
			recognizer.side,
			UITouchPhaseBegan);
		if ([observedTouches count] > 0)
		{
			[recognizer touchesBegan: observedTouches];
		}
	}
}

- (void) handleTouchMovedNotification: (NSNotification*)data
{
    NSSet* touches = data.object;

	//NSLog(@"touchMoved count: %i", (int)touches.count);

	// Notify touch observers.
    for (FFRTouchEventObserver* observer in self.touchObservers)
	{
		if (observer.movedSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.side,
				UITouchPhaseMoved);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.movedSelector
					withObject: observedTouches];
			}
		}
	}

    for (FFRGestureRecognizer* recognizer in self.gestureRecognizers)
	{
		NSSet* observedTouches = filterTouchesBySideAndPhase(
			touches,
			recognizer.side,
			UITouchPhaseMoved);
		if ([observedTouches count] > 0)
		{
			[recognizer touchesMoved: observedTouches];
		}
	}
}

- (void) handleTouchEndedNotification: (NSNotification*)data
{
    NSSet* touches = data.object;

	//NSLog(@"touchEnded count: %i", touches.count);

	// Notify touch observers.
    for (FFRTouchEventObserver* observer in self.touchObservers)
	{
		if (observer.endedSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.side,
				UITouchPhaseEnded);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.endedSelector
					withObject: observedTouches];
			}
		}
	}

	// Notify gesture recognizers.
    for (FFRGestureRecognizer* recognizer in self.gestureRecognizers)
	{
		NSSet* observedTouches = filterTouchesBySideAndPhase(
			touches,
			recognizer.side,
			UITouchPhaseEnded);
		if ([observedTouches count] > 0)
		{
			[recognizer touchesEnded: observedTouches];
		}
	}
}

#pragma clang diagnostic pop

@end
