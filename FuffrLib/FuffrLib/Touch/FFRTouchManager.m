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

extern NSString* FFRFirmwareDownloader_URL;

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

/** Timer that sets the idleTimerDisabled flag. */
@property NSTimer* screenIdleTimerTimer;

/** Time stap for when the most recent touch moved event occured. */
@property (nonatomic, assign) NSTimeInterval lastTouchMovedEventTimeStamp;

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

// Helper function for filtering touch events by side.
static NSSet* filterTouchesBySide(NSSet* touches, FFRSide sides)
{
	// If all sides are set there is no need to filter.
	if (sides == FFRSideAll)
	{
		return touches;
	}

	// Else filter toches by side.
	return [touches objectsPassingTest:
		^BOOL(id obj, BOOL* stop)
		{
			return sides & ((FFRTouch*)obj).side;
		}];
}

// For performance testing, no filtering.
/*
static NSSet* filterTouchesBySide(NSSet* touches, FFRSide sides)
{
	return touches;
}
*/

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

// Public class methods.

+ (FFRTouchManager*) sharedManager
{
	if (NULL == sharedInstance)
	{
		sharedInstance = [FFRTouchManager new];

		[sharedInstance registerPeripheralDiscoverer];
		[sharedInstance registerConnectionCallbacks];
		[sharedInstance registerFirmwareNotification];
	}

	return sharedInstance;
}

+ (void) connectEnableLeftRight
{
	[FFRTouchManager connectEnableSides: FFRSideLeft | FFRSideRight];
}

+ (void) connectEnableSides: (FFRSide)sides
{
	[FFRTouchManager connectEnableSides: sides touchesPerSide: @1];
}

+ (void) connectEnableSides: (FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches
{
	// Scan is started automatically by FFRBLEManager.
	// No need to do this here.
	//[self startScan];

	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Set active sides.
	[manager
		onFuffrConnected:
		^{
			[manager useSensorService:
			^{
				NSLog(@"FFRTouchManager: Fuffr Connected");
				[manager
					enableSides: sides
					touchesPerSide: numberOfTouches];
			}];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"FFRTouchManager: Fuffr Disconnected");
		}];
}

+ (void) enableSides: (FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches
{
	[[FFRTouchManager sharedManager]
		enableSides: sides
		touchesPerSide: numberOfTouches];
}

+ (void) addTouchObserver: (id)object
	touchBegan: (SEL)touchBeganSelector
	touchMoved: (SEL)touchMovedSelector
	touchEnded: (SEL)touchEndedSelector
	sides: (FFRSide)sides
{
	[[FFRTouchManager sharedManager]
		addTouchObserver: object
		touchBegan: touchBeganSelector
		touchMoved: touchMovedSelector
		touchEnded: touchEndedSelector
		sides: sides];
}

// Public instance methods.

- (void) onFuffrConnected: (void(^)())connectedBlock
	onFuffrDisconnected: (void(^)())disconnectedBlock
{
	self.onConnectedBlock = connectedBlock;
	self.onDisconnectedBlock = disconnectedBlock;
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
	if (self.screenIdleTimerTimer)
	{
		[self.screenIdleTimerTimer invalidate];
		self.screenIdleTimerTimer = nil;
	}
		
	[[NSNotificationCenter defaultCenter] removeObserver: self];

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

- (void) updateFirmwareFromURL: (NSString*) url
{
	// Must set URL using global variable prior to update.
	FFRFirmwareDownloader_URL = url;

	// Guard agains multiple invocations during update.
	if (self.firmwareUpdateState != FFRFirmwareUpdateNotInProgress)
	{
		return;
	}

	// Set initial update state.
	self.firmwareUpdateState = FFRFirmwareUpdateInitiated;

	// Initalise progress UI.
	[FFR_SVProgressHUD setBackgroundColor: [UIColor lightGrayColor]];
	[FFR_SVProgressHUD setRingThickness: 4.0];
	[FFR_SVProgressHUD
		showWithStatus: @"Perparing Update 1(2)"
		maskType: FFR_SVProgressHUDMaskTypeBlack];

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
			NSLog(@"FFRTouchManager: Found image version service");

			// Get firmware image version to download.
			[handler queryCurrentImageVersion: ^void (char version)
			{
				NSLog(@"FFRTouchManager: Image type is: %c", version);

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
	NSLog(@"FFRTouchManager: updateFirmwareCC2541");
	[self updateFirmware: @"CC2541" nextState: FFRFirmwareUpdateCC2541];
}

- (void) updateFirmwareMSP430
{
	NSLog(@"FFRTouchManager: updateFirmwareMSP430");
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
				NSLog(@"FFRTouchManager: Got %@ data: %i", firmwareId, (int)[data length]);

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
				NSLog(@"FFRTouchManager: Failed to get %@ data", firmwareId);
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
		[FFR_SVProgressHUD
			showProgress: progress
			status: message
			maskType: FFR_SVProgressHUDMaskTypeBlack];
    }
    else if (state == FFRProgrammingStateWriteCompleted)
	{
		if (FFRFirmwareUpdateCC2541 == self.firmwareUpdateState)
		{
			NSLog(@"FFRTouchManager: Firmware part 1 updated");
			[FFR_SVProgressHUD
				showWithStatus: @"Perparing Update 2(2)"
				maskType: FFR_SVProgressHUDMaskTypeBlack];
        	[self
				performSelector: @selector(updateFirmwareMSP430)
				withObject: nil
				afterDelay: 20.0];
		}
		else if (FFRFirmwareUpdateMSP430 == self.firmwareUpdateState)
		{
			NSLog(@"FFRTouchManager: Firmware part 2 updated");

			[FFR_SVProgressHUD showSuccessWithStatus:@"Firmware updated"];

        	[self performSelector:@selector(firmwareUpdateEnded) withObject:nil afterDelay:3.0];

			NSLog(@"FFRTouchManager: Firmware update done");
			
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
		NSLog(@"FFRTouchManager: Device disconnected during update");

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
		[FFR_SVProgressHUD dismiss];

		// Recreate touch handler.
		[self createTouchHandlerAndRegisterAsTouchDelegate];

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
		// Initialise properties.
		self.connected = NO;
		self.onConnectedBlock = nil;
		self.onDisconnectedBlock = nil;
		self.touchObservers = [NSMutableArray array];
		self.gestureRecognizers = [NSMutableArray array];
		self.peripheralWithMaxRSSI = nil;
		self.activePeripheral = nil;
		self.firmwareUpdateState = FFRFirmwareUpdateNotInProgress;
		// Set default value. Update documentation
		// comment in header file if you change this.
		self.screenIdleTimerTimeout = 5.0;
		self.lastTouchMovedEventTimeStamp = 0.0;

		// Start timer that handles screen stay awake behaviour.
		[self createScreenIdleTimer];

		// Notifications for application active/resign.
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(applicationDidBecomeActive:)
			name: UIApplicationDidBecomeActiveNotification
			object: nil];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(applicationWillResignActive:)
			name: UIApplicationWillResignActiveNotification
			object: nil];
	}
	return self;
}

- (void) dealloc
{
	[self shutDown];
}

- (void) applicationDidBecomeActive: (NSNotification *)notification
{
	NSLog(@"FFRTouchManager: applicationDidBecomeActive");

	[[FFRTouchManager sharedManager] reconnectFuffr];
}

- (void) applicationWillResignActive: (NSNotification *)notification
{
	NSLog(@"FFRTouchManager: applicationWillResignActive");

	[[FFRTouchManager sharedManager] disconnectFuffr];
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
	NSLog(@"FFRTouchManager: startScan");

	// Not needed, scan is started automatically bu central manager.
	// TODO: Perhaps we want to change this?
	//[bleManager startScan: YES];
}

// TODO: Delete. Not used.
- (void) stopScan
{
	NSLog(@"FFRTouchManager: stopScan");

	[[FFRBLEManager sharedManager] stopScan];
}

-(void) connectToDeviceWithMaxRSSI
{
	NSLog(@"FFRTouchManager: connectToDeviceWithMaxRSSI: %@", self.peripheralWithMaxRSSI.name);

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
		NSLog(@"FFRTouchManager: Found device: %@", p.name);

		if (stringContains(p.name, @"Fuffr") ||
			stringContains(p.name, @"Neonode"))
		{
			if (nil == me.peripheralWithMaxRSSI)
			{
				NSLog(@"FFRTouchManager: Start timer for connectToDeviceWithMaxRSSI: %@", p.name);
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
					NSLog(@"FFRTouchManager: Found device with stronger RSSI: %@", p.name);
					me.peripheralWithMaxRSSI = p;
				}
			}
		}
	};
}

- (void) registerConnectionCallbacks
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];

	// Create touch handler as default.
	[self createTouchHandlerAndRegisterAsTouchDelegate];

	__weak FFRBLEManager* manager = bleManager;
	__weak FFRTouchManager* me = self;

	bleManager.onPeriperalConnected =
		^(CBPeripheral* hostPeripheral)
		{
			NSLog(@"FFRTouchManager: onPeriperalConnected");
			[manager.handler setPeripheral: hostPeripheral];
			self.connected = YES;
			if (me.onConnectedBlock)
			{
				me.onConnectedBlock();
			}
		};
		
	bleManager.onPeriperalDisconnected =
		^(CBPeripheral* hostPeripheral)
		{
			NSLog(@"FFRTouchManager: onPeriperalDisconnected");
			self.connected = NO;
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

- (void) createTouchHandlerAndRegisterAsTouchDelegate
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];
	bleManager.handler = [FFRTouchHandler new];
	FFRTouchHandler* touchHandler = bleManager.handler;
	touchHandler.touchDelegate = self;
}

- (void) createScreenIdleTimer
{
	self.screenIdleTimerTimer =
		[NSTimer
			scheduledTimerWithTimeInterval: self.screenIdleTimerTimeout / 2.0
			target: self
			selector: @selector(screenKeepAliveCheck:)
			userInfo: nil
			repeats: YES];
}

- (void) screenKeepAliveCheck: (id) sender
{
	// Set the idleTimerDisabled flag based on when last touch event occured.
	NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
	if (now - self.lastTouchMovedEventTimeStamp >= self.screenIdleTimerTimeout)
	{
		[UIApplication sharedApplication].idleTimerDisabled = NO;
	}
	else
	{
		[UIApplication sharedApplication].idleTimerDisabled = YES;
	}
}

- (void) updateTouchTimeStamp
{
	// Save time stamp.
	self.lastTouchMovedEventTimeStamp = [[NSProcessInfo processInfo] systemUptime];
}

- (void) touchesBegan: (NSSet*)touches
{
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
- (void) touchesMoved: (NSSet*)touches
{
	//NSLog(@"FFRTouchManager touchMoved count: %i", (int)touches.count);

	//logTouches(@"FFRTouchMan moved", touches);

	[self updateTouchTimeStamp];

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

- (void) touchesEnded: (NSSet*)touches
{
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
