//
//  FFRCaseHandler.m
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRCaseHandler.h"
#import "FFROverlaySpaceMapper.h"
#import "FFRBLEExtensions.h"


@interface FFRCaseHandler ()

/**
    Unpacks the bluetooth packet and converts it into a touch object
 */
-(FFRTouch*) unpackData:(NSData*)data fromSide:(FFRCaseSide)side;

@end


@implementation FFRCaseHandler


NSString* const FFRCaseSensorServiceUuid = @"fff0";
NSString* const FFRProximityEnablerCharacteristic = @"fff1";
NSString* const FFRSideLeftUdid = @"fff4";
NSString* const FFRSideBottomUdid = @"fff3";
NSString* const FFRSideRightUdid = @"fff2";
NSString* const FFRSideTopUdid = @"fff5";


-(instancetype) init {
    if (self = [super init]) {
        self.spaceMapper = [[FFROverlaySpaceMapper alloc] init];
        _touches = [[FFRTrackingManager alloc] init];
        _backgroundQueue = dispatch_queue_create("com.fuffr.background", NULL);
    }

    return self;
}

-(instancetype) initWithPeripheral:(CBPeripheral*)peripheral {
    if (self = [self init]) {
        [self loadPeripheral:peripheral];
    }

    return self;
}

-(void) loadPeripheral:(CBPeripheral*) peripheral {
    _peripheral = peripheral;

    // enable sensor sides and proximity in general, spread out commands in time
    [self enableSides:FFRCaseTop|FFRCaseLeft|FFRCaseRight|FFRCaseBottom setOn:TRUE];
    [self performSelector:@selector(enablePeripheral:) withObject:@TRUE afterDelay:0.4];
    //[self enablePeripheral:TRUE];
}

-(void) dealloc {
    _backgroundQueue = nil;

    // disable the case
    //[self enableSides:FFRCaseTop|FFRCaseLeft|FFRCaseRight|FFRCaseBottom setOn:FALSE];
    @try {
        [self enablePeripheral:FALSE];
    }
    @catch (NSException *exception) {
    }
    @finally {
    }
}

#pragma mark - enable/disable sensors

-(void) enableSides:(FFRCaseSide)sides setOn:(BOOL)on {
    if (!_peripheral) {
        NSLog(@"No peripheral loaded in Case handler!");
        return;
    }

    // enabling the sensor sides is spread out in time to prevent connection timeouts, probably because the case becomes busy processing the commands
    if (sides & FFRCaseTop) {
        [self performSelector:@selector(enableTopSide:) withObject:@TRUE afterDelay:0.6];
        //[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideTopUdid enabled:on];
    }

    if (sides & FFRCaseLeft) {
        [self performSelector:@selector(enableLeftSide:) withObject:@TRUE afterDelay:0.7];
        //[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideLeftUdid enabled:on];
    }

    if (sides & FFRCaseRight) {
        [self performSelector:@selector(enableRightSide:) withObject:@TRUE afterDelay:0.8];
        //[_peripheral setNotificationForCharacteristicWithIdentifier:FFRSideRightUdid enabled:on];
    }

    if (sides & FFRCaseBottom) {
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

-(void) enablePeripheral:(NSNumber*)on {
    const int DataLength = 1;

    // enable sensors
    Byte value[DataLength];
    memset(value, 0, DataLength);
    value[0] = 1;

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

    NSLog(@"case sensor(s) activated: %d", on.boolValue);
}

#pragma mark - Bluetooth

-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic {
    dispatch_async(_backgroundQueue, ^{
        FFRTouch* touch = nil;
        FFRCaseSide side = FFRCaseNotSet;

        if ([characteristic.UUID isEqualToString:FFRSideLeftUdid]) {
            //NSLog(@"reading left side data");
            side = FFRCaseLeft;
        }
        else if ([characteristic.UUID isEqualToString:FFRSideRightUdid]) {
            //NSLog(@"reading right side data");
            side = FFRCaseRight;
        }
        else if ([characteristic.UUID isEqualToString:FFRSideTopUdid]) {
            //NSLog(@"reading top side data");
            side = FFRCaseTop;
        }
        else if ([characteristic.UUID isEqualToString:FFRSideBottomUdid]) {
            //NSLog(@"reading bottom side data");
            side = FFRCaseBottom;
        }

        if (side != FFRCaseNotSet) {
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

-(FFRTouch*) unpackData:(NSData*)data fromSide:(FFRCaseSide)side {
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

-(CGPoint) normalizePoint:(CGPoint)point onSide:(FFRCaseSide)side {
    const float FFRLongXResolution = 3327.0;
    const float FFRLongYResolution = 1878.0;
    const float FFRShortXResolution = 1279.0;
    const float FFRShortYResolution = 876.0;

    CGPoint p;
    switch (side) {
        case FFRCaseRight:
            p = CGPointMake(point.y / FFRLongYResolution, point.x / FFRLongXResolution);
            break;
        case FFRCaseLeft:
            p = CGPointMake(1 - point.y / FFRLongYResolution, 1 - point.x / FFRLongXResolution);
            break;
        case FFRCaseBottom:
            p = CGPointMake(point.x / FFRShortXResolution, point.y / FFRShortYResolution);
            break;
        case FFRCaseTop:
            p = CGPointMake(1 - point.x / FFRShortXResolution, 1 - point.y / FFRShortYResolution);
            break;
        default:
            break;
    }

    return p;
}


@end
