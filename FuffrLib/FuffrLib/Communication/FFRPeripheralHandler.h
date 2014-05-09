//
//  FFRPeripheralHandler.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-14.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRTouch.h"

/**
    Simple protocol for handling a BLE peripheral
 */
@protocol FFRPeripheralHandler <NSObject>

/**
    Connect the hander to the peripheral
 */
-(void) loadPeripheral:(CBPeripheral*) peripheral;

/**
 * Enable sides of Fuffr.
 * @param sides Bitwise or:ed values (FFRSideTop, FFRSideLeft, FFRSideRight, FFRSideBottom)
 * @param on YES or NO
 */
- (void) enableSides:(FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches;

-(void) getBatteryLevel;

/**
 Called when notifyable characteristics update their values
 */
-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;

/**
 Callback when writing to characteristics (if not requesting write with no response)
 */
-(void) didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

/**
 The device was disconnected
 */
-(void) deviceDisconnected:(CBPeripheral *)peripheral;

@end
