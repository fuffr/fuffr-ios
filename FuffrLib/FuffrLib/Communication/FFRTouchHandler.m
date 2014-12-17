//
//  FFRCaseHandler.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRTouchHandler.h"
#import "FFROverlaySpaceMapper.h"
#import "FFRBLEExtensions.h"
#import "FFRBLEManager.h"

/**
 * Enable data.
 */
typedef struct
{
	union {
		Byte sides;
		struct {
			Byte right : 1;
			Byte bottom : 1;
			Byte left : 1;
			Byte top : 1;
			// other bits are ignored.
		};
	};
	// values 0 to 5 are valid.
	// values higher than 5 are changed to 0.
	Byte pointsPerSide;
} FFREnableData;

@interface FFRTouchHandler ()

/**
 * Unpacks the bluetooth packet and converts it into a touch object.
 */
-(FFRTouch*) unpackData:(FFRRawTouchData)raw;

@end

@implementation FFRTouchHandler

NSString* const FFRCaseSensorServiceUUID = @"fff0";
NSString* const FFRProximityEnablerCharacteristic = @"fff1";
NSString* const FFRTouchCharacteristicUUID1 = @"fff2";
NSString* const FFRTouchCharacteristicUUID2 = @"fff3";
NSString* const FFRTouchCharacteristicUUID3 = @"fff4";
NSString* const FFRTouchCharacteristicUUID4 = @"fff5";
NSString* const FFRTouchCharacteristicUUID5 = @"fff6";
NSString* const FFRBatteryServiceUUID = @"180f";
NSString* const FFRBatteryCharacteristicUUID = @"2a19";

static const FFRSide SideLookupTable[4] =
{
	FFRSideRight,
	FFRSideBottom,
	FFRSideLeft,
	FFRSideTop
};

#pragma mark - init/dealloc

-(instancetype) init
{
	if (self = [super init])
	{
		_numTouchesPerSide = 0;
		_touchQueue = dispatch_queue_create("com.fuffr.touchqueue", DISPATCH_QUEUE_SERIAL);
		memset(_touches, 0, sizeof(_touches));
		self.spaceMapper = [FFROverlaySpaceMapper new];
		self.touchDelegate = nil;

		// Timer that handles removal of inactive touches.
		_touchRemoveTimeout = 0.20;
		_touchPruneTimer = [NSTimer
			scheduledTimerWithTimeInterval: _touchRemoveTimeout / 3.0
			target: self
			selector: @selector(timerPruneTouches:)
			userInfo: nil
			repeats: YES];

		// Enable UI orientation readings.
		//[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(statusBarOrientationDidChange:)
			name: UIApplicationDidChangeStatusBarOrientationNotification
			object: nil];
		self.userInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
	}

	return self;
}

-(void) dealloc
{
	[self shutDown];
}

-(void) shutDown
{
	if (_touchPruneTimer)
	{
		[_touchPruneTimer invalidate];
		_touchPruneTimer = nil;
	}

	_touchQueue = nil;
	_peripheral = nil;
	self.spaceMapper = nil;
	self.touchDelegate = nil;

	//[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void) setPeripheral:(CBPeripheral*) peripheral
{
	_peripheral = peripheral;
}

#pragma mark - Service discovery

- (void) useSensorService: (void(^)())serviceAvailableBlock
{
	[[FFRBLEManager sharedManager]
		useService: FFRCaseSensorServiceUUID
		whenAvailable: serviceAvailableBlock];
}

- (void) useBatteryService: (void(^)())serviceAvailableBlock
{
	[[FFRBLEManager sharedManager]
		useService: FFRBatteryServiceUUID
		whenAvailable: serviceAvailableBlock];
}

/**
 * Remove all touches.
 */
-(void) clearAllTouches
{
	// Old code: [_trackingHandler clearAllTouches];
	// TODO: Implement. (Set all array elements to nil?)
}

#pragma mark - Enable/disable sensors

/*
From release notes document 2014-03-28:
"Implemented MSP430 power saving features. If no active side
(select side BitMap = 0x00) is selected MSP430 goes into 
sleep mode. This is a very low power mode in which the MSP430 
will halt all CPU operation and scanning and wait for command 
from the CC2541 until then continuing operation again. This 
LowPowerMode is also implemented when MSP430 is waiting for 
NN1001 ASIC scan to be completed and also waiting for CC2541 
to read data from MSP430."
*/
-(void) enableSides:(FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches
{
	if (!_peripheral)
	{
		return;
	}

	// Turn off touch handling by setting number of touches to zero.
	// This is to fix a bug that crashes the case when there are touch
	// events coming while enabling sides.
	[self setActiveSides: FFRSideNotSet touchesPerSide: 0];

	// Enable touch notifications. All notification charactertistics
	// are enabled regardsless of number of touches/sides set.
	// Touches are updated data is received.

	// Alternative call not used.
	//[self
	//	performSelector:@selector(enableTouchNotificationsForCharacteristic:)
	//	withObject:FFRSideTopUUID
	//	afterDelay:0.0];

	if (numberOfTouches > 0)
	{
		[self enableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID1];
		[self enableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID2];
		[self enableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID3];
		[self enableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID4];
		[self enableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID5];
	}
	else
	{
		[self disableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID1];
		[self disableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID2];
		[self disableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID3];
		[self disableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID4];
		[self disableTouchNotificationsForCharacteristic: FFRTouchCharacteristicUUID5];
	}

	// Set active sides and number of touches per side (this is a global value for all sides).
	[self setActiveSides: (FFRSide)sides touchesPerSide: numberOfTouches.intValue];
}

-(void) enableTouchNotificationsForCharacteristic:(NSString*)uuidString
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_peripheral
			ffr_setNotificationForCharacteristicWithIdentifier: uuidString
			enabled: YES];
	});
	NSLog(@"FFRCaseHandler: enabled touch characteristic: %@", uuidString);
}

-(void) disableTouchNotificationsForCharacteristic:(NSString*)uuidString
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[_peripheral
			ffr_setNotificationForCharacteristicWithIdentifier: uuidString
			enabled: NO];
	});
	NSLog(@"FFRCaseHandler: disabled touch characteristic: %@", uuidString);
}

/*
From release notes document 2014-03-28:
"Implemented selectable amount of touches by using the
Enabler byte (0xFFF1 GATT attribute). Setting Enabler 
byte to 1 gives 1 reported touch coordinate per selected
side. Setting 2 gives 2 and so on. Maximum selectable is
currently 5 touches. Setting 0 will disable the touch detection."
*/
-(void) setActiveSides: (FFRSide)sides touchesPerSide: (Byte)numTouchesPerSide
{
	// Save number of touches per side.
	_numTouchesPerSide = numTouchesPerSide;

	FFREnableData enableData;
	enableData.sides = 0;
	enableData.left = (sides & FFRSideLeft) ? 1 : 0;
	enableData.right = (sides & FFRSideRight) ? 1 : 0;
	enableData.top = (sides & FFRSideTop) ? 1 : 0;
	enableData.bottom = (sides & FFRSideBottom) ? 1 : 0;
	enableData.pointsPerSide = numTouchesPerSide;

	NSData* data = [NSData dataWithBytes:&enableData length:sizeof(enableData)];
	__weak CBPeripheral* p = _peripheral;
	//TODO: Why is try/catch needed? And why are not any errors handled?
	@try
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			[p ffr_writeCharacteristicWithIdentifier:FFRProximityEnablerCharacteristic data:data];
		});
	}
	@catch (NSException *exception)
	{
	}
	@finally
	{
	}

	// TODO: Remove commented out code.
	//[_peripheral writeCharacteristicWithoutResponseForIdentifier:FFRProximityServiceUUID data:data];

	NSLog(@"FFRCaseHandler: touches: %d left: %d right: %d top: %d bottom: %d",
		enableData.pointsPerSide,
		enableData.left,
		enableData.right,
		enableData.top,
		enableData.bottom);
}

#pragma mark - BLE notifications

-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
{
	dispatch_async(_touchQueue,
	^{
		// Do we have touch updates?
		if ([characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID1] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID2] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID3] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID4] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID5])
		{
			size_t count = characteristic.value.length / sizeof(FFRRawTouchData);

			// Ensure correct length.
			if (characteristic.value.length % sizeof(FFRRawTouchData) != 0)
			{
				NSLog(@"Bad touch count length!");
				return;
			}

			__weak FFRTouchHandler* me = self;
			dispatch_async(dispatch_get_main_queue(),
			^{
				[me
					unpackAndSendTouchEventsForCharacteristic: characteristic
					eventCount: count];
			});
		}
	});
}

-(void) unpackAndSendTouchEventsForCharacteristic: (CBCharacteristic *)characteristic
	eventCount: (size_t) count
{
	// Copy data to touch buffer.
	FFRRawTouchData raw[count];
	[characteristic.value getBytes:raw length:characteristic.value.length];

	// Sets for touch events.
	NSMutableSet* touchesBegan = nil;
	NSMutableSet* touchesMoved = nil;
	NSMutableSet* touchesEnded = nil;

	// Unpack data.
	for (size_t i = 0; i < count; i++)
	{
		FFRRawTouchData data = raw[i];
		if (data.identifier > 0)
		{
			FFRTouch* touch = [self unpackData: data];
			if (touch)
			{
				if (FFRTouchPhaseBegan == touch.phase)
				{
					if (nil == touchesBegan)
					{
						touchesBegan = [NSMutableSet new];
					}
					[touchesBegan addObject: touch];
				}
				else if (FFRTouchPhaseMoved == touch.phase)
				{
					if (nil == touchesMoved)
					{
						touchesMoved = [NSMutableSet new];
					}
					[touchesMoved addObject: touch];
				}
				else if (FFRTouchPhaseEnded == touch.phase)
				{
					if (nil == touchesEnded)
					{
						touchesEnded = [NSMutableSet new];
					}
					[touchesEnded addObject: touch];
				}
			}
		}
	}

	// Send touch objects.
	if (nil != touchesBegan)
	{
		[self sendTouchesBegan: touchesBegan];
	}
	if (nil != touchesMoved)
	{
		[self sendTouchesMoved: touchesMoved];
	}
	if (nil != touchesEnded)
	{
		[self sendTouchesEnded: touchesEnded];
	}
}

-(void) sendTouchesBegan: (NSSet*) touches
{
	// Notify touch delegate.
	if (nil != touches && nil != self.touchDelegate)
	{
		[self.touchDelegate touchesBegan: touches];
	}
}

-(void) sendTouchesMoved: (NSSet*) touches
{
	// Notify touch delegate.
	if (nil != touches && nil != self.touchDelegate)
	{
		[self.touchDelegate touchesMoved: touches];
	}
}

-(void) sendTouchesEnded: (NSSet*) touches
{
	// Notify touch delegate.
	if (nil != touches && nil != self.touchDelegate)
	{
		[self.touchDelegate touchesEnded: touches];
	}
}

-(void) timerPruneTouches:(id) sender
{
	dispatch_async(dispatch_get_main_queue(),
	^{
		NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
		NSMutableSet* touchesEnded = nil;

		for (int i = 0; i < 32; ++i)
		{
			FFRTouch* touch = _touches[i];
			if ((nil != touch) &&
				(FFRTouchPhaseBegan == touch.phase ||
				 FFRTouchPhaseMoved == touch.phase) &&
				(now - touch.timestamp >= _touchRemoveTimeout))
			{
				//NSLog(@"***Pruning id: %d, side: %d", (int)touch.identifier, touch.side);

				if (nil == touchesEnded)
				{
					touchesEnded = [NSMutableSet new];
				}
				touch.phase = FFRTouchPhaseEnded;
				[touchesEnded addObject: touch];
			}
		}

		if (nil != touchesEnded)
		{
			[self sendTouchesEnded: touchesEnded];
		}
	});
}

-(void) didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	// TODO: Improve error handling.
	if (error)
	{
		// Trap error for debugging.
		NSLog(@"didWriteValueForCharacteristic error: %@", error);
		// Don't kill the app!!
		//assert(false);

		// What effect will this have exactly? (This is the original code.)
		// TODO: Should we comment this out?
		_peripheral = nil;
	}
}

-(void) peripheralDisconnected:(CBPeripheral *)peripheral
{
	NSLog(@"FFRCaseHandler: peripheralDisconnected");

	[self clearAllTouches];
}

#pragma mark - Touch data handling

-(FFRTouch*) unpackData:(FFRRawTouchData)raw
{
	Byte identifier = raw.identifier;

	int sideIndex = (identifier - 1) / _numTouchesPerSide;
	FFRSide side = SideLookupTable[sideIndex];
	CGPoint rawPoint = CGPointMake((raw.highX << 8) | raw.lowX, (raw.highY << 8) | raw.lowY);
	CGPoint normalizedPoint = [self normalizePoint:rawPoint onSide:side];

	bool down = raw.down;

	// Get touch object.
	FFRTouch* touch = _touches[identifier];

	// Create touch object if not exisiting.
	if (nil == touch)
	{
		touch = [FFRTouch new];
		_touches[identifier] = touch;
		touch.identifier = identifier;
		touch.phase = FFRTouchPhaseEnded; // Initial state
	}

 	// Began?
	if (down && FFRTouchPhaseEnded == touch.phase)
	{
		touch.phase = FFRTouchPhaseBegan;
	}
 	// Moved?
	else if (down && FFRTouchPhaseEnded != touch.phase)
	{
		touch.phase = FFRTouchPhaseMoved;
	}
 	// Ended?
	else if (!down && FFRTouchPhaseEnded != touch.phase)
	{
		touch.phase = FFRTouchPhaseEnded;
	}
	// Unknown state.
	else
	{
		return nil;
	}

	//if (touch.phase != FFRTouchPhaseMoved)
	//	NSLog(@"  @@@ unpackData id: %i down: %i phase: %i", identifier, down, touch.phase);

	touch.timestamp = [[NSProcessInfo processInfo] systemUptime];
	touch.side = side;
	touch.rawPoint = rawPoint;
	touch.normalizedLocation = [self mapNormalizedPoint: normalizedPoint];
	touch.location = [self.spaceMapper
		locationOnScreen: touch.normalizedLocation
		fromSide: side];

	return touch;
}

-(CGPoint) normalizePoint:(CGPoint)point onSide:(FFRSide)side
{
	// Old values (before 2014-04-28).
	/*
	const float FFRLongXResolution = 3327.0;
	const float FFRLongYResolution = 1878.0;
	const float FFRShortXResolution = 1279.0;
	const float FFRShortYResolution = 876.0;
	*/

	// New values (from 2014-04-28).
	const float FFRLongXResolution = 32767.0;
	const float FFRLongYResolution = 32767.0;
	const float FFRShortXResolution = 32767.0;
	const float FFRShortYResolution = 32767.0;

	CGPoint p;
	switch (side) {
		case FFRSideRight:
			p = CGPointMake(point.y / FFRLongYResolution, point.x / FFRLongXResolution);
			break;
		case FFRSideLeft:
			p = CGPointMake(1 - point.y / FFRLongYResolution, 1 - point.x / FFRLongXResolution);
			break;
		case FFRSideBottom:
			p = CGPointMake(point.x / FFRShortXResolution, point.y / FFRShortYResolution);
			break;
		case FFRSideTop:
			p = CGPointMake(1 - point.x / FFRShortXResolution, 1 - point.y / FFRShortYResolution);
			break;
		default:
			break;
	}

	return p;
}

-(CGPoint) mapNormalizedPoint: (CGPoint)point
{
	CGPoint p = point;

	if (UIInterfaceOrientationPortraitUpsideDown == self.userInterfaceOrientation)
	{
		p.x = 1.0 - point.x;
		p.y = 1.0 - point.y;
		return p;
	}
	else if (UIInterfaceOrientationLandscapeRight == self.userInterfaceOrientation)
	{
		p.y = 1.0 - point.x;
		p.x = point.y;
		return p;
	}
	else if (UIInterfaceOrientationLandscapeLeft == self.userInterfaceOrientation)
	{
		p.y = point.x;
		p.x = 1.0 - point.y;
		return p;
	}
	else
	{
		return p;
	}
}

- (void) statusBarOrientationDidChange: (NSNotification *)notification
{
	UIInterfaceOrientation orientation =
		[UIApplication sharedApplication].statusBarOrientation;

	if (UIInterfaceOrientationPortrait == orientation ||
		UIInterfaceOrientationPortraitUpsideDown == orientation ||
		UIInterfaceOrientationLandscapeLeft == orientation ||
		UIInterfaceOrientationLandscapeRight == orientation)
	{
		self.userInterfaceOrientation = orientation;
	}
}

@end
