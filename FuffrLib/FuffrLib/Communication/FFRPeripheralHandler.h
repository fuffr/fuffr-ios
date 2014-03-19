//
//  FFRPeripheralHandler.h
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-14.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
    Simple protocol for handling a BLE peripheral
 */
@protocol FFRPeripheralHandler <NSObject>


/**
    Connect the hander to the peripheral
 */
-(void) loadPeripheral:(CBPeripheral*) peripheral;

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
