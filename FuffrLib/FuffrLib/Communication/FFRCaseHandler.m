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


@interface FFRCaseHandler ()

/**
    Unpacks the bluetooth packet and converts it into a touch object
 */
-(FFRTouch*) unpackData:(NSData*)data fromSide:(FFRSide)side;

@end

@implementation FFRCaseHandler

NSString* const FFRCaseSensorServiceUuid = @"fff0";
NSString* const FFRProximityEnablerCharacteristic = @"fff1";
NSString* const FFRSideLeftUdid = @"fff4";
NSString* const FFRSideBottomUdid = @"fff3";
NSString* const FFRSideRightUdid = @"fff2";
NSString* const FFRSideTopUdid = @"fff5";

-(instancetype) init
{
    if (self = [super init]) {
        self.spaceMapper = [[FFROverlaySpaceMapper alloc] init];
        _touches = [[FFRTrackingManager alloc] init];
        _backgroundQueue = dispatch_queue_create("com.fuffr.background", NULL);
    }

    return self;
}

// TODO: Seems to never be called?
-(instancetype) initWithPeripheral:(CBPeripheral*)peripheral {
    if (self = [self init]) {
        [self loadPeripheral:peripheral];
    }

    return self;
}

-(void) loadPeripheral:(CBPeripheral*) peripheral
{
    _peripheral = peripheral;
}

-(void) dealloc
{
    _backgroundQueue = nil;

    // disable the case
    @try {
        [self enablePeripheral: 0];
    }
    @catch (NSException *exception) {
    }
    @finally {
    }
}

#pragma mark - enable/disable sensors

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
    if (!_peripheral) {
        NSLog(@"No peripheral loaded in Case handler!");
        return;
    }

	[self
		performSelector: @selector(enablePeripheral:)
		withObject: numberOfTouches
		afterDelay: 0.4];

    // enabling the sensor sides is spread out in time to prevent connection timeouts, probably because the case becomes busy processing the commands
    if (sides & FFRSideTop) {
        [self performSelector:@selector(enableTopSide:) withObject:@TRUE afterDelay:0.6];
        //[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideTopUdid enabled:on];
    }

    if (sides & FFRSideLeft) {
        [self performSelector:@selector(enableLeftSide:) withObject:@TRUE afterDelay:0.7];
        //[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideLeftUdid enabled:on];
    }

    if (sides & FFRSideRight) {
        [self performSelector:@selector(enableRightSide:) withObject:@TRUE afterDelay:0.8];
        //[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideRightUdid enabled:on];
    }

    if (sides & FFRSideBottom) {
        [self performSelector:@selector(enableBottomSide:) withObject:@TRUE afterDelay:0.9];
        //[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideBottomUdid enabled:on];
    }
}

-(void) enableTopSide:(NSNumber*)on {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideTopUdid enabled:on.boolValue];
    });
    NSLog(@"case top enabled: %d", on.boolValue);
}

-(void) enableLeftSide:(NSNumber*)on {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideLeftUdid enabled:on.boolValue];
    });
    NSLog(@"case left enabled: %d", on.boolValue);
}

-(void) enableRightSide:(NSNumber*)on {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideRightUdid enabled:on.boolValue];
    });
    NSLog(@"case right enabled: %d", on.boolValue);
}

-(void) enableBottomSide:(NSNumber*)on {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideBottomUdid enabled:on.boolValue];
    });
    NSLog(@"case bottom enabled: %d", on.boolValue);
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
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            [p writeCharacteristicWithIdentifier:FFRProximityEnablerCharacteristic data:data];
        });
    }
    @catch (NSException *exception) {
    }
    @finally {
    }

    //[_peripheral writeCharacteristicWithoutResponseForIdentifier:FFRProximityServiceUdid data:data];

    NSLog(@"case sensor(s) activated per side: %d", touchesPerSide.intValue);
}

#pragma mark - Bluetooth

-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic {
    dispatch_async(_backgroundQueue, ^{
        FFRTouch* touch = nil;
        FFRSide side = FFRSideNotSet;

        if ([characteristic.UUID isEqualToString:FFRSideLeftUdid]) {
            //NSLog(@"reading left side data");
            side = FFRSideLeft;
        }
        else if ([characteristic.UUID isEqualToString:FFRSideRightUdid]) {
            //NSLog(@"reading right side data");
            side = FFRSideRight;
        }
        else if ([characteristic.UUID isEqualToString:FFRSideTopUdid]) {
            //NSLog(@"reading top side data");
            side = FFRSideTop;
        }
        else if ([characteristic.UUID isEqualToString:FFRSideBottomUdid]) {
            //NSLog(@"reading bottom side data");
            side = FFRSideBottom;
        }

        if (side != FFRSideNotSet) {
            touch = [self unpackData:characteristic.value fromSide:side];
            [_touches handleNewOrChangedTrackingObject:touch];
        }
    });
}

-(void) didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"case handler didWriteValueForCharacteristic: %@, error: %@", characteristic, error);

    if (error) {
        _peripheral = nil;
    }
}

-(void) deviceDisconnected:(CBPeripheral *)peripheral {
    NSLog(@"case handler: deviceDisconnected");
}

#pragma mark - touch data handling

-(FFRTouch*) unpackData:(NSData*)data fromSide:(FFRSide)side {
    FFRRawTrackingData raw;
    [data getBytes:&raw length:sizeof(FFRRawTrackingData)];

    CGPoint rawPoint = CGPointMake((raw.highX << 8) | raw.lowX, (raw.highY << 8) | raw.lowY);
    CGPoint normalizedPoint = [self normalizePoint:rawPoint onSide:side];

    //NSLog(@"raw: %@, side: %d, normalized: %@", NSStringFromCGPoint(rawPoint), side, NSStringFromCGPoint(normalizedPoint));

    FFRTouch* touch = [[FFRTouch alloc] init];
    touch.identifier = raw.identifier;
    touch.rawPoint = rawPoint;
    touch.side = side;
    touch.normalizedLocation = normalizedPoint;
    touch.location = [self.spaceMapper locationOnScreen:normalizedPoint fromSide:side];

    return touch;
}

-(CGPoint) normalizePoint:(CGPoint)point onSide:(FFRSide)side {
    const float FFRLongXResolution = 3327.0;
    const float FFRLongYResolution = 1878.0;
    const float FFRShortXResolution = 1279.0;
    const float FFRShortYResolution = 876.0;

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
