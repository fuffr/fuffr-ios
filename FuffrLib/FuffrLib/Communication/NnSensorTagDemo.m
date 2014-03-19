//
//  NnSensorTagDemo.m
//  SensorCaseDemo
//
//  Created by Christoffer Sjöberg on 2013-10-25.
//  Copyright (c) 2013 Neonode. All rights reserved.
//

#import "NnSensorTagDemo.h"
#import "NnBLEExtensions.h"


NSString* const tiSensorTag = @"12DD01F4-D190-A5C8-5E02-C122262D5804";
NSString* const tiAcceleratorService = @"f000aa10-0451-4000-b000-000000000000";
NSString* const tiAcceleratorConfig = @"f000aa12-0451-4000-b000-000000000000";
NSString* const tiAcceleratorPeriod = @"f000aa13-0451-4000-b000-000000000000";
NSString* const tiAcceleratorData = @"f000aa11-0451-4000-b000-000000000000";


@implementation NnSensorTagDemo


-(id) init {
    if (self = [super init]) {
        self.monitoredDeviceIdentifier = tiSensorTag;
        //[NSTimer scheduledTimerWithTimeInterval:0.02f target:self selector:@selector(interpolate:) userInfo:nil repeats:YES];

        __weak NnSensorTagDemo* _self = self;
        [self addMonitoredService:tiAcceleratorService onDiscovery:^(CBService *service, CBPeripheral* hostPeripheral) {
            //[_self performSelector:@selector(connectSensorTag:) withObject:hostPeripheral afterDelay:1];
            [_self connectSensorTag:hostPeripheral];
        }];
    }

    return self;
}

-(void) dealloc {
    uint8_t data = 0;

    // TOOD: should really verify it is the sensortag..
    for (CBPeripheral* peripheral in self.connectedDevices) {
        [peripheral writeCharacteristicWithIdentifier:tiAcceleratorConfig data:[NSData dataWithBytes:&data length:1]];
        [peripheral setNotificationForCharacteristicWithIdentifier:tiAcceleratorData enabled:FALSE];
    }
}

-(void) connectSensorTag:(CBPeripheral*)peripheral {
    NSLog(@"connect to sensor tag: %@", peripheral);

    uint8_t periodData = 10;
    uint8_t data = 1;

    // enable accelerator, set update period
    [peripheral writeCharacteristicWithIdentifier:tiAcceleratorConfig data:[NSData dataWithBytes:&data length:1]];
    [peripheral writeCharacteristicWithIdentifier:tiAcceleratorPeriod data:[NSData dataWithBytes:&periodData length:1]];
    [peripheral setNotificationForCharacteristicWithIdentifier:tiAcceleratorData enabled:TRUE];
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    LOGMETHOD

    if ([characteristic.UUID isEqualToString:tiAcceleratorData]) {
        NSLog(@"reading accelerometer data");
        [self getAccelerometerValues:characteristic.value];
    }

    NSLog(@"p: %@, characteristic: %@", peripheral, characteristic);
}

#pragma mark - Data reading

-(void) getAccelerometerValues:(NSData*)dataValue {
    float x = [self calcXValue:dataValue];
    float y = [self calcYValue:dataValue];
    float z = [self calcZValue:dataValue];

    NSLog(@"accelerometer x,y,z: (%f, %f, %f)", x, y, z);

    x = MIN(MAX(0, self.ballLocation.x + x*3), _simulatedField.width);
    y = MIN(MAX(0, self.ballLocation.y + y*3), _simulatedField.height);
    self.ballLocation = CGPointMake(x, y);

    //_reportedShift = CGPointMake(x, y);
}

const float KXTJ9_RANGE = 4.0;

-(float) calcXValue:(NSData*)data {
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[0] * 1.0) / (256 / KXTJ9_RANGE));
}

-(float) calcYValue:(NSData*)data {
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[1] * 1.0) / (256 / KXTJ9_RANGE)) * -1;
}

-(float) calcZValue:(NSData*)data {
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[2] * 1.0) / (256 / KXTJ9_RANGE));
}

#pragma mark - Ball simulation

-(void) setSimulatedField:(CGSize)size {
    _simulatedField = size;
    self.ballLocation = CGPointMake(size.width*0.5, size.height*0.5);
}

-(void) interpolate:(NSTimer *)timer {
    if (_currentShift.x != _reportedShift.x || _currentShift.y != _reportedShift.y) {
        _currentShift = CGPointMake(_currentShift.x + 0.02*(_reportedShift.x-_currentShift.x), _currentShift.y + 0.02*(_reportedShift.y-_currentShift.y));
    }

    float x = MIN(MAX(0, self.ballLocation.x + _currentShift.x), _simulatedField.width) ;
    float y = MIN(MAX(0, self.ballLocation.y + _currentShift.y), _simulatedField.height);

    if (self.ballLocation.x != x || self.ballLocation.y != y) {
        self.ballLocation = CGPointMake(x, y);
    }
}


@end
