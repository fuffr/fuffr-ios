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

@interface FFRCaseHandler ()

/**
	Unpacks the bluetooth packet and converts it into a touch object
 */
-(FFRTouch*) unpackData:(FFRRawTrackingData)raw fromSide:(FFRSide)side;

@end

@implementation FFRCaseHandler

NSString* const FFRCaseSensorServiceUUID = @"fff0";
NSString* const FFRProximityEnablerCharacteristic = @"fff1";
NSString* const FFRSideLeftUUID = @"fff4";
NSString* const FFRSideBottomUUID = @"fff3";
NSString* const FFRSideRightUUID = @"fff2";
NSString* const FFRSideTopUUID = @"fff5";

NSString* const FFRBatteryServiceUUID = @"180f";
NSString* const FFRBatteryCharacteristicUUID = @"2a19";

#pragma mark - init/dealloc

-(instancetype) init
{
	if (self = [super init]) {
		_backgroundQueue = dispatch_queue_create("com.fuffr.background", nil);
		self.spaceMapper = [[FFROverlaySpaceMapper alloc] init];
		_trackingManager = [[FFRTrackingManager alloc] init];
		_trackingManager.backgroundQueue = _backgroundQueue;
		memset(_previousTouchDown, 0, sizeof(_previousTouchDown));
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
	if (_trackingManager)
	{
		[_trackingManager shutDown];
		_trackingManager = nil;
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
	[_trackingManager clearAllTouches];
}

#pragma mark - Enable/disable sensors

/*
From release notes document 2014-03-28:
Implemented MSP430 power saving features. If no active side 
(select side BitMap = 0x00) is selected MSP430 goes into 
sleep mode. This is a very low power mode in which the MSP430 
will halt all CPU operation and scanning and wait for command 
from the CC2541 until then continuing operation again. This 
LowPowerMode is also implemented when MSP430 is waiting for 
NN1001 ASIC scan to be completed and also waiting for CC2541 
to read data from MSP430.
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
	[self
		performSelector: @selector(enablePeripheral:)
		withObject: @0
		afterDelay: 0.0];

	// Enabling the sensor sides is spread out in time to prevent connection timeouts,
	// probably because the case becomes busy processing the commands.
	// TODO: Is there an alternative to rely on timing?! What about queueing write
	// requests, and perform them as soon as the previous write is done?
	// Does the sensor case confirm updates?
	if (sides & FFRSideTop)
	{
		[self performSelector:@selector(enableTopSide:) withObject:@TRUE afterDelay:0.0];
		//[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideTopUUID enabled:on];
	}
	else
	{
		[self performSelector:@selector(enableTopSide:) withObject:@FALSE afterDelay:0.0];
	}

	if (sides & FFRSideLeft)
	{
		[self performSelector:@selector(enableLeftSide:) withObject:@TRUE afterDelay:0.0];
		//[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideLeftUUID enabled:on];
	}
	else
	{
		[self performSelector:@selector(enableLeftSide:) withObject:@FALSE afterDelay:0.0];
	}

	if (sides & FFRSideRight)
	{
		[self performSelector:@selector(enableRightSide:) withObject:@TRUE afterDelay:0.0];
		//[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideRightUUID enabled:on];
	}
	else
	{
		[self performSelector:@selector(enableRightSide:) withObject:@FALSE afterDelay:0.0];
	}

	if (sides & FFRSideBottom)
	{
		[self performSelector:@selector(enableBottomSide:) withObject:@TRUE afterDelay:0.0];
		//[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideBottomUUID enabled:on];
	}
	else
	{
		[self performSelector:@selector(enableBottomSide:) withObject:@FALSE afterDelay:0.0];
	}

	// Set number of touches per side (this is a global value for all sides).
	[self
		performSelector: @selector(enablePeripheral:)
		withObject: numberOfTouches
		afterDelay: 0.0];
}

-(void) enableTopSide:(NSNumber*)on {
	dispatch_async(dispatch_get_main_queue(), ^{
		[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideTopUUID enabled:on.boolValue];
	});
	NSLog(@"FFRCaseHandler: top enabled: %d", on.boolValue);
}

-(void) enableLeftSide:(NSNumber*)on {
	dispatch_async(dispatch_get_main_queue(), ^{
		[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideLeftUUID enabled:on.boolValue];
	});
	NSLog(@"FFRCaseHandler: left enabled: %d", on.boolValue);
}

-(void) enableRightSide:(NSNumber*)on {
	dispatch_async(dispatch_get_main_queue(), ^{
		[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideRightUUID enabled:on.boolValue];
	});
	NSLog(@"FFRCaseHandler: right enabled: %d", on.boolValue);
}

-(void) enableBottomSide:(NSNumber*)on {
	dispatch_async(dispatch_get_main_queue(), ^{
		[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideBottomUUID enabled:on.boolValue];
	});
	NSLog(@"FFRCaseHandler: bottom enabled: %d", on.boolValue);
}

/*
From release notes document 2014-03-28:
Implemented selectable amount of touches by using the 
Enabler byte (0xFFF1 GATT attribute). Setting Enabler 
byte to 1 gives 1 reported touch coordinate per selected
side. Setting 2 gives 2 and so on. Maximum selectable is
currently 5 touches. Setting 0 will disable the touch detection.
*/
-(void) enablePeripheral: (NSNumber*)touchesPerSide
{
	const int DataLength = 1;

	// enable sensors
	Byte value[DataLength];
	memset(value, 0, DataLength);

	// Origical code:
	//value[0] = 1;

	// New code:
	value[0] = (Byte) touchesPerSide.intValue;

	NSData* data = [NSData dataWithBytes:&value length:DataLength];
	__weak CBPeripheral* p = _peripheral;
	//TODO: Why is try/catch needed? And why are not any errors handled?
	@try {
		dispatch_async(dispatch_get_main_queue(), ^{
			[p writeCharacteristicWithIdentifier:FFRProximityEnablerCharacteristic data:data];
		});
	}
	@catch (NSException *exception) {
	}
	@finally {
	}

	//[_peripheral writeCharacteristicWithoutResponseForIdentifier:FFRProximityServiceUUID data:data];

	NSLog(@"FFRCaseHandler: num sensor(s) activated per side: %d", touchesPerSide.intValue);
}

#pragma mark - BLE notifications

-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
{
	dispatch_async(_backgroundQueue, ^{
		FFRSide side = FFRSideNotSet;

		if ([characteristic.UUID isEqualToString:FFRSideLeftUUID]) {
			//NSLog(@"reading left side data");
			side = FFRSideLeft;
		}
		else if ([characteristic.UUID isEqualToString:FFRSideRightUUID]) {
			//NSLog(@"reading right side data");
			side = FFRSideRight;
		}
		else if ([characteristic.UUID isEqualToString:FFRSideTopUUID]) {
			//NSLog(@"reading top side data");
			side = FFRSideTop;
		}
		else if ([characteristic.UUID isEqualToString:FFRSideBottomUUID]) {
			//NSLog(@"reading bottom side data");
			side = FFRSideBottom;
		}

		if (side != FFRSideNotSet) {
			// ensure correct length.
			if(characteristic.value.length % sizeof(FFRRawTrackingData) != 0) {
				NSLog(@"Bad characteristic length!");
				return;
			}
			// extract raw data.
			size_t count = characteristic.value.length / sizeof(FFRRawTrackingData);
			FFRRawTrackingData raw[count];
			[characteristic.value getBytes:raw length:characteristic.value.length];
			// unpack data.
			for(size_t i=0; i<count; i++) {
				FFRTouch* touch = [self unpackData:raw[i] fromSide:side];
				if(touch) {
					[_trackingManager handleNewOrChangedTrackingObject:touch];
				}
			}
		}
		else {
			NSLog(@"FFRSideNotSet - this should not happen, aborting");
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
		//assert(false);

		// What effect will this have exactly? (This is the original code.)
		_peripheral = nil;
	}
}

-(void) peripheralDisconnected:(CBPeripheral *)peripheral
{
	NSLog(@"FFRCaseHandler: peripheralDisconnected");

	// Tell tracking manager to remove all touch objects.
	[_trackingManager clearAllTouches];
}

#pragma mark - Touch data handling

// For debugging.
//static int NumberOfActiveTouches = 0;

-(FFRTouch*) unpackData:(FFRRawTrackingData)raw fromSide:(FFRSide)side
{
	CGPoint rawPoint = CGPointMake((raw.highX << 8) | raw.lowX, (raw.highY << 8) | raw.lowY);
	CGPoint normalizedPoint = [self normalizePoint:rawPoint onSide:side];

	Byte identifier = raw.identifier;
	bool down = raw.down;
	bool previousDown = _previousTouchDown[identifier];
	_previousTouchDown[identifier] = down;
	
	//if (eventType != 1) NSLog(@"Touch id: %d, event: %d, side: %d", identifier, eventType, side);
	
	//NSLog(@"Touch id: %d, event: %d, side: %d, rawPoint: %@, normalized: %@", identifier, eventType, side, NSStringFromCGPoint(rawPoint), NSStringFromCGPoint(normalizedPoint));
	
	// if touch remains inactive, return nil.
	if(!down && !previousDown)
		return nil;

	FFRTouch* touch = [[FFRTouch alloc] init];
	touch.identifier = identifier;
	if (down && !previousDown) { touch.phase = FFRTouchPhaseBegan; }
	else if (down && previousDown) { touch.phase = FFRTouchPhaseMoved; }
	else if (!down && previousDown) { touch.phase = FFRTouchPhaseEnded; }

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
