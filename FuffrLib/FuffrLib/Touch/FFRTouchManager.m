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
@property FFRSide sides;

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
static NSSet* filterTouchesBySideAndPhase(NSSet* touches, FFRSide sides, FFRTouchPhase phase)
{
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			//return (sides & ((FFRTouch*)obj).side) && (phase == ((FFRTouch*)obj).phase);
			return (sides & ((FFRTouch*)obj).side);
		}];
}

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

	// TODO: Call connectedBlock if already connected?
	// And do the same in onFuffrConnected?
	// There could be a situation where this method is
	// called "too late" and you will never call the
	// connected block.
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
	NSLog(@"FFRTouchManager: App called disconnectFuffr");

	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	self.activeDevice = [bleManager connectedDevice];
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

- (void) useSensorService: (void(^)())serviceAvailableBlock
{
	[[FFRBLEManager sharedManager].handler
		useSensorService: serviceAvailableBlock];
}

- (void) enableSides:(FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	[bleManager.handler enableSides: sides touchesPerSide: numberOfTouches];
}

- (void) addTouchObserver: (id)object
	touchBegan: (SEL)touchBeganSelector
	touchMoved: (SEL)touchMovedSelector
	touchEnded: (SEL)touchEndedSelector
	sides: (FFRSide)sides
{
	FFRTouchEventObserver* observer = [FFRTouchEventObserver new];
	observer.object = object;
	observer.beganSelector = touchBeganSelector;
	observer.movedSelector = touchMovedSelector;
	observer.endedSelector = touchEndedSelector;
	observer.sides = sides;
	observer.touchBlock = nil;
	observer.touchBlockId = 0;
	[self.touchObservers addObject: observer];
}

- (void) removeTouchObserver: (id)object
{
	[self.touchObservers removeObject: object];
}

- (int) addTouchBeganBlock: (void(^)(NSSet* touches))block
	sides: (FFRSide)sides
{
	FFRTouchEventObserver* observer = [self
		addTouchBlockObserver: block
		sides: sides];
	observer.beganSelector = @selector(callBlockWithTouches:);
	return observer.touchBlockId;
}

- (int) addTouchMovedBlock: (void(^)(NSSet* touches))block
	sides: (FFRSide)sides
{
	FFRTouchEventObserver* observer = [self
		addTouchBlockObserver: block
		sides: sides];
	observer.movedSelector = @selector(callBlockWithTouches:);
	return observer.touchBlockId;
}

- (int) addTouchEndedBlock: (void(^)(NSSet* touches))block
	sides: (FFRSide)sides
{
	FFRTouchEventObserver* observer = [self
		addTouchBlockObserver: block
		sides: sides];
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
	[self registerConnectionCallbacks];
	return self;
}

// Internal helper method.
- (FFRTouchEventObserver*) addTouchBlockObserver: (void(^)(NSSet* touches))block
	sides: (FFRSide)sides
{
	FFRTouchEventObserver* observer = [FFRTouchEventObserver new];
	observer.object = observer;
	observer.beganSelector = nil;
	observer.movedSelector = nil;
	observer.endedSelector = nil;
	observer.sides = sides;
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

	// This is where we connect.
	[[FFRBLEManager sharedManager] connectPeripheral: self.deviceWithMaxRSSI];
}

- (void) registerPeripheralDiscoverer
{
	__weak FFRTouchManager* me = self;

	// Set discovery callback.
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	bleManager.onPeripheralDiscovered = ^(CBPeripheral* p)
	{
		NSLog(@"Found device: %@", p.name);

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

// TODO: Remove old code. Callback used instead of KVO.
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

- (void) registerConnectionCallbacks
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];

	// Create BLE manager handler object.
	bleManager.handler = [FFRCaseHandler new];

	__weak FFRBLEManager* manager = bleManager;
	__weak FFRTouchManager* me = self;

	bleManager.onPeriperalConnected =
		^(CBPeripheral* hostPeripheral)
		{
			NSLog(@"initFuffr onPeriperalConnected");
			[manager.handler setPeripheral: hostPeripheral];
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

	//NSLog(@"FFRTouchManager touchBegan count: %i", (int)touches.count);
	//logTouches(@"FFRTouchMan began", touches);

	// Notify touch observers.
	NSArray* observers = [self.touchObservers copy];
	for (FFRTouchEventObserver* observer in observers)
	{
		if (observer.beganSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.sides,
				FFRTouchPhaseBegan);
			//NSLog(@"observedTouches began: %i", (int)observedTouches.count);
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

	//NSLog(@"FFRTouchManager touchMoved count: %i", (int)touches.count);

	//logTouches(@"FFRTouchMan moved", touches);

	// Notify touch observers.
	NSArray* observers = [self.touchObservers copy];
	for (FFRTouchEventObserver* observer in observers)
	{
		if (observer.movedSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.sides,
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

	//NSLog(@"FFRTouchManager touchEnded count: %i", (int)touches.count);
	
	//logTouches(@"FFRTouchMan ended", touches);

	// Notify touch observers.
	NSArray* observers = [self.touchObservers copy];
	for (FFRTouchEventObserver* observer in observers)
	{
		if (observer.endedSelector)
		{
			NSSet* observedTouches = filterTouchesBySideAndPhase(
				touches,
				observer.sides,
				FFRTouchPhaseEnded);
			//NSLog(@"observedTouches ended: %i", (int)observedTouches.count);
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
