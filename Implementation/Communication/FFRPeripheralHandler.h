//
//  FFRPeripheralHandler.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-14.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Protocol for handling a BLE peripheral.
 */
@protocol FFRPeripheralHandler <NSObject>

/**
 * Initialize the handler for the peripheral.
 */
-(void) setPeripheral:(CBPeripheral*)peripheral;

/**
 * Called when notifyable characteristics update their values.
 */
-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;

/**
 * Callback when writing to characteristics (if not requesting write with no response).
 */
-(void) didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

/**
 * The device was disconnected.
 */
-(void) peripheralDisconnected:(CBPeripheral *)peripheral;

/**
 * Turn off handler and deallocate resources.
 */
-(void) shutDown;

@end
