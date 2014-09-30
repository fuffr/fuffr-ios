//
//  FFRCaseHandler.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRCaseHandler.h"
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

@interface FFRCaseHandler ()

/**
 * Unpacks the bluetooth packet and converts it into a touch object.
 */
-(FFRTouch*) unpackData:(FFRRawTrackingData)raw;

@end

@implementation FFRCaseHandler

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
		_backgroundQueue = dispatch_queue_create("com.fuffr.background", nil);
		self.spaceMapper = [[FFROverlaySpaceMapper alloc] init];
		_trackingHandler = [[FFRTrackingHandler alloc] init];
		_trackingHandler.backgroundQueue = _backgroundQueue;
		memset(_previousTouchDown, 0, sizeof(_previousTouchDown));

		// Timer that handles removal of inactive touches.
		_touchRemoveTimeout = 0.20;
		_timer = [NSTimer
			scheduledTimerWithTimeInterval: _touchRemoveTimeout / 3.0
			target: self
			selector: @selector(timerPruneTouches:)
			userInfo: nil
			repeats: YES];
	}

	return self;
}

-(void) setPeripheral:(CBPeripheral*) peripheral
{
	_peripheral = peripheral;
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
	
	if (_trackingHandler)
	{
		[_trackingHandler shutDown];
		_trackingHandler = nil;
	}

	_backgroundQueue = nil;
	self.spaceMapper = nil;
	_peripheral = nil;
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
 * Tell the tracking manager to remove all touches.
 */
-(void) clearAllTouches
{
	[_trackingHandler clearAllTouches];
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
	dispatch_async(_backgroundQueue,
	^{
		// Do we have touch updates?
		if ([characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID1] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID2] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID3] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID4] ||
			[characteristic.UUID ffr_isEqualToString:FFRTouchCharacteristicUUID5])
		{
			size_t count = characteristic.value.length / sizeof(FFRRawTrackingData);

			// Ensure correct length.
			if (characteristic.value.length % sizeof(FFRRawTrackingData) != 0)
			{
				NSLog(@"Bad touch count length!");
				return;
			}

			[self
				unpackAndSendTouchEventsForCharacteristic: characteristic
				eventCount: count];
		}
	});
}

-(void) unpackAndSendTouchEventsForCharacteristic: (CBCharacteristic *)characteristic
	eventCount: (size_t) count
{
	// Copy data to touch buffer.
	FFRRawTrackingData raw[count];
	[characteristic.value getBytes:raw length:characteristic.value.length];

	// Sets for touch events.
	NSMutableSet* touchesBegan = nil;
	NSMutableSet* touchesMoved = nil;
	NSMutableSet* touchesEnded = nil;

	// Unpack data.
	for (size_t i = 0; i < count; i++)
	{
		FFRRawTrackingData data = raw[i];
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
		[_trackingHandler dispatchTouchesBegan: touchesBegan];
	}
	else if (nil != touchesMoved)
	{
		//NSLog(@"=== touchesMoved: %i", (int)touchesMoved.count);
		[_trackingHandler dispatchTouchesMoved: touchesMoved];
	}
	else if (nil != touchesEnded)
	{
		[_trackingHandler dispatchTouchesEnded: touchesEnded];
	}
}

-(void) timerPruneTouches:(id) sender
{
	//NSLog(@"timerPruneTouches queue: %s", dispatch_queue_get_label(dispatch_get_current_queue()));
	dispatch_async(_backgroundQueue,
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

		[_trackingHandler dispatchTouchesEnded: touchesEnded];
	});
}

-(void) didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
	// TODO: Improve error handling.
	if (error)
	{
		// Trap error for debugging.
		NSLog(@"didWriteValueForCharacteristic error: %@", error);
		//assert(false);

		// What effect will this have exactly? (This is the original code.)
		_peripheral = nil;
	}
}

-(void) peripheralDisconnected:(CBPeripheral *)peripheral
{
	NSLog(@"FFRCaseHandler: peripheralDisconnected");

	// Tell tracking manager to remove all touch objects.
	[_trackingHandler clearAllTouches];
}

#pragma mark - Touch data handling

// For debugging.
//static int NumberOfActiveTouches = 0;

-(FFRTouch*) unpackData:(FFRRawTrackingData)raw
{
	Byte identifier = raw.identifier;

	int sideIndex = (identifier - 1) / _numTouchesPerSide;
	FFRSide side = SideLookupTable[sideIndex];
	CGPoint rawPoint = CGPointMake((raw.highX << 8) | raw.lowX, (raw.highY << 8) | raw.lowY);
	CGPoint normalizedPoint = [self normalizePoint:rawPoint onSide:side];

	bool down = raw.down;
	bool previousDown = _previousTouchDown[identifier];
	_previousTouchDown[identifier] = down;

	// if touch remains inactive, return nil.
	if (!down && !previousDown)
	{
		return nil;
	}

	// Get the touch object.
	if (nil == _touches[identifier])
	{
		_touches[identifier] = [FFRTouch new];
	}
	FFRTouch* touch = _touches[identifier];

	touch.identifier = identifier;
	if (down && !previousDown) { touch.phase = FFRTouchPhaseBegan; }
	else if (down && previousDown) { touch.phase = FFRTouchPhaseMoved; }
	else if (!down && previousDown) { touch.phase = FFRTouchPhaseEnded; }
	//else if (!down && !previousDown) { touch.phase = FFRTouchPhaseInactive; }

	touch.timestamp = [[NSProcessInfo processInfo] systemUptime];
	touch.side = side;
	touch.rawPoint = rawPoint;
	touch.normalizedLocation = normalizedPoint;
	touch.location = [self.spaceMapper locationOnScreen:normalizedPoint fromSide:side];

#if 0
	if(touch.phase != FFRTouchPhaseMoved) {
		NSLog(@"Touch id: %d, down: %d, phase: %d, side: %d, rawcoord: %@", identifier, down, touch.phase, side, NSStringFromCGPoint(rawPoint));
	}
#endif
	// Debug log for down/up events (but not moved).
	//if (eventType != 1)
	//{
		//if (0 == eventType) { ++NumberOfActiveTouches; }
		//if (2 == eventType) { --NumberOfActiveTouches; }
		//NSLog(@"Touch id: %d, event: %d, side: %d, rawcoord: %@, activeTouches: %i", identifier, eventType, side, NSStringFromCGPoint(rawPoint), NumberOfActiveTouches);
		
		//NSLog(@"Touch id: %d, event: %d, side: %d, rawcoord: %@", identifier, eventType, side, NSStringFromCGPoint(rawPoint));
	//}

	return touch;
}

-(CGPoint) normalizePoint:(CGPoint)point onSide:(FFRSide)side {
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

@end
