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
 *
 * This class also holds touch blocks. A bit of a shortcut,
 * and potentially confusing but simplifies code since just 
 * one class is used. Also note that this is an internal class
 * that is not exposed to the public API. Therefore it can
 * be changed if another implementation is desired.
 *
 * Note the trick of delegating the block call to the event
 * observer itself using selector callBlockWithTouches:.
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

// Touch block (used by the block touch listener mechanism).
@property (nonatomic, copy) void(^touchBlock)(NSSet* touches);

// Id used to identify a touch block. Used for removal.
@property int touchBlockId;

// Method that calls the block.
- (void) callBlockWithTouches: (NSSet*)touches;

@end

@implementation FFRTouchEventObserver

- (void) callBlockWithTouches: (NSSet*)touches
{
	if (self.touchBlock)
	{
		self.touchBlock(touches);
	}
}

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
 * Connected and disconnected blocks.
 * Invoked when app is connected/disconnected to Fuffr.
 */
@property (nonatomic, copy) void(^onConnectedBlock)();
@property (nonatomic, copy) void(^onDisconnectedBlock)();

/** List of touch observers (instances of FFRTouchEventObserver). */
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
		options:NSCaseInsensitiveSearch].length > 0;
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
static NSSet* filterTouchesBySideAndPhase(NSSet* touches, FFRSide side, FFRTouchPhase phase)
{
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			return (side & ((FFRTouch*)obj).side) && (phase == ((FFRTouch*)obj).phase);
		}];
}

// Singleton instance.
static FFRTouchManager* sharedInstance = NULL;

// Touch block id counter.
static int touchBlockIdCounter = 0;

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

- (void) onFuffrConnected: (void(^)())connectedBlock
	onFuffrDisconnected: (void(^)())disconnectedBlock
{
	self.onConnectedBlock = connectedBlock;
	self.onDisconnectedBlock = disconnectedBlock;

	// Scan is started automatically by FFRBLEManager.
	// No need to do this here.
	//[self startScan];
}

- (void) onFuffrConnected: (void(^)())connectedBlock
{
	self.onConnectedBlock = connectedBlock;
}

- (void) onFuffrDisconnected: (void(^)())disconnectedBlock
{
	self.onDisconnectedBlock = disconnectedBlock;
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
	observer.touchBlock = nil;
	observer.touchBlockId = 0;
	[self.touchObservers addObject: observer];
}

- (void) removeTouchObserver: (id)object
{
	[self.touchObservers removeObject: object];
}

- (int) addTouchBeganBlock: (void(^)(NSSet* touches))block
	side: (FFRSide)side
{
	FFRTouchEventObserver* observer = [self
		addTouchBlockObserver: block
		side: side];
	observer.beganSelector = @selector(callBlockWithTouches:);
	return observer.touchBlockId;
}

- (int) addTouchMovedBlock: (void(^)(NSSet* touches))block
	side: (FFRSide)side
{
	FFRTouchEventObserver* observer = [self
		addTouchBlockObserver: block
		side: side];
	observer.movedSelector = @selector(callBlockWithTouches:);
	return observer.touchBlockId;
}

- (int) addTouchEndedBlock: (void(^)(NSSet* touches))block
	side: (FFRSide)side
{
	FFRTouchEventObserver* observer = [self
		addTouchBlockObserver: block
		side: side];
	observer.endedSelector = @selector(callBlockWithTouches:);
	return observer.touchBlockId;
}

- (void) removeTouchBlock: (int)blockId
{
	FFRTouchEventObserver* observerToRemove = nil;

	// Find observer to remove.
	for (FFRTouchEventObserver* observer in self.touchObservers)
	{
		if (observer.touchBlockId == blockId)
		{
			observerToRemove = observer;
			break;
		}
	}

	// Remove it.
	if (observerToRemove)
	{
		[self.touchObservers removeObject: observerToRemove];
	}
}

- (void) removeAllTouchObserversAndTouchBlocks
{
	[self.touchObservers removeAllObjects];
}

-(void) addGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer
{
	[self.gestureRecognizers addObject: gestureRecognizer];
}

-(void) removeGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer
{
	[self.gestureRecognizers removeObject: gestureRecognizer];
}

- (void) removeAllGestureRecognizers
{
	[self.gestureRecognizers removeAllObjects];
}

// Internal instance methods.

- (id) init
{
	self.onConnectedBlock = nil;
	self.onDisconnectedBlock = nil;
	self.touchObservers = [NSMutableArray array];
	self.gestureRecognizers = [NSMutableArray array];
	self.deviceWithMaxRSSI = nil;
	self.activeDevice = nil;
	[self registerTouchMethods];
	[self registerPeripheralDiscoverer];
	return self;
}

// Internal helper method.
- (FFRTouchEventObserver*) addTouchBlockObserver: (void(^)(NSSet* touches))block
	side: (FFRSide)side
{
	FFRTouchEventObserver* observer = [FFRTouchEventObserver new];
	observer.object = observer;
	observer.beganSelector = nil;
	observer.movedSelector = nil;
	observer.endedSelector = nil;
	observer.side = side;
	observer.touchBlock = block;
	observer.touchBlockId = ++touchBlockIdCounter;
	[self.touchObservers addObject: observer];
	return observer;
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
	NSLog(@"connectToDeviceWithMaxRSSI: %@", self.deviceWithMaxRSSI.name);
	[[FFRBLEManager sharedManager] connectPeripheral: self.deviceWithMaxRSSI];
	[self initFuffr];
}

- (void) registerPeripheralDiscoverer
{
	__weak FFRTouchManager* me = self;

	// Set discovery callback.
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	bleManager.onPeripheralDiscovered = ^(CBPeripheral* p)
	{
		NSLog(@"Found peripheral: %@", p.name);

		if (stringContains(p.name, @"Fuffr") ||
			stringContains(p.name, @"Neonode"))
		{
			if (nil == me.deviceWithMaxRSSI)
			{
				NSLog(@"start timer for connectToDeviceWithMaxRSSI: %@", p.name);
				me.deviceWithMaxRSSI = p;
				[NSTimer
					scheduledTimerWithTimeInterval: 1.0
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
					NSLog(@"Found device with stronger RSSI: %@", p.name);
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
		
		// OLD CODE
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

	bleManager.sensorServiceUUID = FFRCaseSensorServiceUUID;
	__weak FFRBLEManager* manager = bleManager;
	__weak FFRTouchManager* me = self;

	bleManager.onCharacteristicsDiscovered =
		^(CBService* service, CBPeripheral* hostPeripheral)
		{
			NSLog(@"initFuffr onCharacteristicsDiscovered");
			[manager.handler loadPeripheral:hostPeripheral];
			if (me.onConnectedBlock)
			{
				me.onConnectedBlock();
			}
		};

	bleManager.onPeriperalDisconnected =
		^(CBPeripheral* hostPeripheral)
		{
			NSLog(@"initFuffr onPeriperalDisconnected");
			if (me.onDisconnectedBlock)
			{
				me.onDisconnectedBlock();
			}
		};

	// OLD CODE
	/*[bleManager
		addMonitoredService: FFRCaseSensorServiceUUID
		onDiscovery: ^(CBService* service, CBPeripheral* hostPeripheral)
		{
			NSLog(@"initFuffr loadPeripheral monitored service");
			[manager.handler loadPeripheral:hostPeripheral];
			me.onConnectedBlock();
		}
	];*/
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
	NSArray* observers = [self.touchObservers copy];
	for (FFRTouchEventObserver* observer in observers)
	{
		if (observer.beganSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.side,
				FFRTouchPhaseBegan);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.beganSelector
					withObject: observedTouches];
			}
		}
	}

	// Notify gesture recognizers.
	NSArray* recognizers = [self.gestureRecognizers copy];
	for (FFRGestureRecognizer* recognizer in recognizers)
	{
		NSSet* observedTouches = filterTouchesBySideAndPhase(
			touches,
			recognizer.side,
			FFRTouchPhaseBegan);
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
	NSArray* observers = [self.touchObservers copy];
	for (FFRTouchEventObserver* observer in observers)
	{
		if (observer.movedSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.side,
				FFRTouchPhaseMoved);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.movedSelector
					withObject: observedTouches];
			}
		}
	}

	// Notify gesture recognizers.
	NSArray* recognizers = [self.gestureRecognizers copy];
	for (FFRGestureRecognizer* recognizer in recognizers)
	{
		NSSet* observedTouches = filterTouchesBySideAndPhase(
			touches,
			recognizer.side,
			FFRTouchPhaseMoved);
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
	NSArray* observers = [self.touchObservers copy];
	for (FFRTouchEventObserver* observer in observers)
	{
		if (observer.endedSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.side,
				FFRTouchPhaseEnded);
			if ([observedTouches count] > 0)
			{
				[observer.object
					performSelector:observer.endedSelector
					withObject: observedTouches];
			}
		}
	}

	// Notify gesture recognizers.
	NSArray* recognizers = [self.gestureRecognizers copy];
	for (FFRGestureRecognizer* recognizer in recognizers)
	{
		NSSet* observedTouches = filterTouchesBySideAndPhase(
			touches,
			recognizer.side,
			FFRTouchPhaseEnded);
		if ([observedTouches count] > 0)
		{
			[recognizer touchesEnded: observedTouches];
		}
	}
}

#pragma clang diagnostic pop

@end
