//
//  FFRTouchManager.m
//  This is a high-level touch and connection mananger for
//  the FuffrLib.
//
//  Created by Fuffr on 07/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRTouchManager.h"
#import "FFRFirmwareDownloader.h"
#import "SVProgressHUD.h"

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
@property CBPeripheral* peripheralWithMaxRSSI;

/**
 * The device we are connected to. Used when reconnecting.
 */
@property CBPeripheral* activePeripheral;

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

/** Firmware update state. */
@property NSInteger firmwareUpdateState;

/** Firmware A/B version. */
@property char firmwareImageVersion;

/**
 * Type that defines constants for firmware update states.
 */
typedef enum
{
	FFRFirmwareUpdateNotInProgress = 0,
	FFRFirmwareUpdateInitiated = 1,
	FFRFirmwareUpdateCC2541 = 2,
	FFRFirmwareUpdateMSP430 = 3
}
FFRFirmwareUpdate;

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
static NSSet* filterTouchesBySide(NSSet* touches, FFRSide side)
{
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			return side & ((FFRTouch*)obj).side;
		}];
}

/* Unused
static NSSet* filterTouchesBySideAndPhase(NSSet* touches, FFRSide sides, FFRTouchPhase phase)
{
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			return (sides & ((FFRTouch*)obj).side) && (phase == ((FFRTouch*)obj).phase);
		}];
}
*/

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
		
		[sharedInstance registerTouchMethods];
		[sharedInstance registerPeripheralDiscoverer];
		[sharedInstance registerConnectionCallbacks];
		[sharedInstance registerFirmwareNotification];
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
	self.activePeripheral = [bleManager connectedPeripheral];
	if (self.activePeripheral != nil)
	{
		[bleManager disconnectPeripheral: self.activePeripheral];
	}
}

- (void) reconnectFuffr
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	if (self.activePeripheral != nil)
	{
		[bleManager connectPeripheral: self.activePeripheral];
	}
}

- (void) shutDown
{
	[self disconnectFuffr];
}

- (void) useSensorService: (void(^)())serviceAvailableBlock
{
	[[FFRBLEManager sharedManager].handler
		useSensorService: serviceAvailableBlock];
}

- (void) useBatteryService: (void(^)())serviceAvailableBlock
{
	[[FFRBLEManager sharedManager].handler
		useBatteryService: serviceAvailableBlock];
}

- (void) useImageVersionService: (void(^)())serviceAvailableBlock
{
	[[FFRBLEManager sharedManager].handler
		useImageVersionService: serviceAvailableBlock];
}

- (void) updateFirmware
{
	// Guard agains multiple invocations during update.
	if (self.firmwareUpdateState != FFRFirmwareUpdateNotInProgress)
	{
		return;
	}

	// Set initial update state.
	self.firmwareUpdateState = FFRFirmwareUpdateInitiated;

	// Initalise progress UI.
	[SVProgressHUD setBackgroundColor: [UIColor lightGrayColor]];
	[SVProgressHUD setRingThickness: 4.0];
	[SVProgressHUD
		showWithStatus: @"Perparing Update 1(2)"
		maskType: SVProgressHUDMaskTypeBlack];

	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];

	// Current handler is case handler.
	[bleManager.handler useSensorService:
	^{
		// Turn off and release case handler.
		[bleManager.handler enableSides: FFRSideNotSet touchesPerSide: @0];
		[bleManager.handler shutDown];
		bleManager.handler = nil;

		// Create OAD handler.
		FFROADHandler* handler = [FFROADHandler alloc];
		[handler setPeripheral: [bleManager connectedPeripheral]];

		// Set OAD handler.
		bleManager.handler = handler;

		// Scan for required service.
		[bleManager.handler useImageVersionService:
		^{
			NSLog(@"Found image version service");

			// Get firmware image version to download.
			[handler queryCurrentImageVersion: ^void (char version)
			{
				NSLog(@"*** Image type is: %c", version);

				// Update to the version not running.
				self.firmwareImageVersion = ('A' == version ? 'B' : 'A');

				[self
					performSelector: @selector(updateFirmwareCC2541)
					withObject: nil
					afterDelay: 2.0];
			}];
		}];
	}];
}

- (void) updateFirmwareCC2541
{
	NSLog(@"updateFirmwareCC2541");
	[self updateFirmware: @"CC2541" nextState: FFRFirmwareUpdateCC2541];
}

- (void) updateFirmwareMSP430
{
	NSLog(@"updateFirmwareMSP430");
	[self updateFirmware: @"MSP430" nextState: FFRFirmwareUpdateMSP430];
}

- (void) updateFirmware: (NSString*)firmwareId nextState: (int)state
{
	[[FFRFirmwareDownloader new]
		downloadFirmware: firmwareId
		version: self.firmwareImageVersion
		callback: ^void(NSData* data)
		{
			if (data)
			{
				NSLog(@"Got %@ data: %i", firmwareId, (int)[data length]);

				BOOL started = [[FFRBLEManager sharedManager].handler
					validateAndLoadImage: data];
				if (started)
				{
					self.firmwareUpdateState = state;
				}
				else
				{
					self.firmwareUpdateState = FFRFirmwareUpdateNotInProgress;
				}
			}
			else
			{
				NSLog(@"Failed to get %@ data", firmwareId);
				self.firmwareUpdateState = FFRFirmwareUpdateNotInProgress;
			}
		}];
}

- (void) firmwareProgress: (NSNotification*) data
{
    FFRProgrammingState state = [(NSNumber*)[data.userInfo
		objectForKey: FFRProgrammingUserInfoStateKey] intValue];
    float progress = [(NSNumber*)[data.userInfo
		objectForKey: FFRProgrammingUserInfoProgressKey] floatValue];
    int secondsLeft = [(NSNumber*)[data.userInfo
		objectForKey: FFRProgrammingUserInfoTimeLeftKey] floatValue];

    if (state == FFRProgrammingStateWriting)
	{
		NSString* message =
			[NSString stringWithFormat:@"%@: %d:%02d",
				(FFRFirmwareUpdateCC2541 == self.firmwareUpdateState) ? @"Update 1(2)" : @"Update 2(2)",
				secondsLeft / 60,
				secondsLeft % 60];
		[SVProgressHUD
			showProgress: progress
			status: message
			maskType: SVProgressHUDMaskTypeBlack];
    }
    else if (state == FFRProgrammingStateWriteCompleted)
	{
		if (FFRFirmwareUpdateCC2541 == self.firmwareUpdateState)
		{
			NSLog(@"Firmware part 1 updated");
			[SVProgressHUD
				showWithStatus: @"Perparing Update 2(2)"
				maskType: SVProgressHUDMaskTypeBlack];
        	[self
				performSelector: @selector(updateFirmwareMSP430)
				withObject: nil
				afterDelay: 20.0];
		}
		else if (FFRFirmwareUpdateMSP430 == self.firmwareUpdateState)
		{
			NSLog(@"Firmware part 2 updated");

			[SVProgressHUD showSuccessWithStatus:@"Firmware updated"];

        	[self performSelector:@selector(firmwareUpdateEnded) withObject:nil afterDelay:3.0];

			NSLog(@"Firmware update done");
			
			UIAlertView *alertView = [[UIAlertView alloc]
				initWithTitle:@"Firmware Upgraded"
				message:@"Press Reset then press Scan on the Fuffr to connect."
				delegate:self
				cancelButtonTitle:@"OK"
				otherButtonTitles:nil];
			[alertView show];
		}
    }
    else if (state == FFRProgrammingStateFailedDueToDeviceDisconnect)
	{
		NSLog(@"Device disconnected during update");

        [self performSelector:@selector(firmwareUpdateEnded) withObject:nil afterDelay:3.0];

		UIAlertView *alertView = [[UIAlertView alloc]
			initWithTitle:@"Fuffr Disconnected"
			message:@"Fuffr disconnected during update. Please quit app, reset Fuffr, restart and connect again."
			delegate:self
			cancelButtonTitle:@"OK"
			otherButtonTitles:nil];
		[alertView show];
    }
    else if (state == FFRProgrammingStateIdle)
	{
        [self performSelector:@selector(firmwareUpdateEnded) withObject:nil afterDelay:3.0];
	}
}

- (void)firmwareUpdateEnded
{
	if (self.firmwareUpdateState != FFRFirmwareUpdateNotInProgress)
	{
		[SVProgressHUD dismiss];

		// Recreate sensor case handler.
		[FFRBLEManager sharedManager].handler = [FFRCaseHandler new];

		self.firmwareUpdateState = FFRFirmwareUpdateNotInProgress;
	}
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
	if (self = [super init])
	{
		self.onConnectedBlock = nil;
		self.onDisconnectedBlock = nil;
		self.touchObservers = [NSMutableArray array];
		self.gestureRecognizers = [NSMutableArray array];
		self.peripheralWithMaxRSSI = nil;
		self.activePeripheral = nil;
		self.firmwareUpdateState = FFRFirmwareUpdateNotInProgress;
	}
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

	// Not needed, scan is started automatically bu central manager.
	// TODO: Perhaps we want to change this?
	//[bleManager startScan: YES];
}

// TODO: Delete. Not used.
- (void) stopScan
{
	NSLog(@"stopScan");

	[[FFRBLEManager sharedManager] stopScan];
}

-(void) connectToDeviceWithMaxRSSI
{
	NSLog(@"connectToDeviceWithMaxRSSI: %@", self.peripheralWithMaxRSSI.name);

	// This is where we connect.
	[[FFRBLEManager sharedManager] connectPeripheral: self.peripheralWithMaxRSSI];
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
			if (nil == me.peripheralWithMaxRSSI)
			{
				NSLog(@"start timer for connectToDeviceWithMaxRSSI: %@", p.name);
				me.peripheralWithMaxRSSI = p;
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
				NSNumber* rssiMax = me.peripheralWithMaxRSSI.discoveryRSSI;
				NSNumber* rssiNew = p.discoveryRSSI;
				if (rssiNew.intValue > rssiMax.intValue)
				{
					NSLog(@"Found device with stronger RSSI: %@", p.name);
					me.peripheralWithMaxRSSI = p;
				}
			}
		}
	};
}

- (void) registerConnectionCallbacks
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];

	// Create sensor case handler as default.
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

- (void) registerFirmwareNotification
{
	// Add firmware notification update observer.
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(firmwareProgress:)
		name: FFRProgrammingNotification
		object: nil];
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
			NSSet* observedTouches = filterTouchesBySide(
				touches,
				observer.sides);
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
		NSSet* observedTouches = filterTouchesBySide(
			touches,
			recognizer.side);
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
			NSSet* observedTouches = filterTouchesBySide(
				touches,
				observer.sides);
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
		NSSet* observedTouches = filterTouchesBySide(
			touches,
			recognizer.side);
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
			NSSet* observedTouches = filterTouchesBySide(
				touches,
				observer.sides);
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
		NSSet* observedTouches = filterTouchesBySide(
			touches,
			recognizer.side);
		if ([observedTouches count] > 0)
		{
			[recognizer touchesEnded: observedTouches];
		}
	}
}

#pragma clang diagnostic pop

@end
