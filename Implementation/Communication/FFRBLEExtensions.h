//
//  FFRBLEExtensions.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-28.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface CBService (FFRExtensions)

/**
    Searches for a characteristic in the service, given a string UUID
 */
-(CBCharacteristic*) ffr_characteristicWithIdentifier:(NSString*)identifier;

@end

@interface CBPeripheral (FFRExtensions)

/**
 Searches for a service on the peripheral, given a string UUID
 */
-(CBService*) ffr_serviceWithIdentifier:(NSString*)identifier;

/**
 Searches for a characteristic on the peripheral and specific service, given a string UUID
 */
-(CBCharacteristic*) ffr_characteristicWithIdentifier:(NSString*)identifier inService:(NSString*)serviceIdentifier;

/**
 Searches for a characteristic on the peripheral, given a string UUID
 */
-(CBCharacteristic*) ffr_characteristicWithIdentifier:(NSString *)identifier;

/**
 Writes to the characteristic on the peripheral, given a string UUID. A search is performed to find the characteristic
 A callback on the peripheral delegate will be called
 */
-(void) ffr_writeCharacteristicWithIdentifier:(NSString*)identifier data:(NSData*)data;

/**
 Writes to the characteristic without waiting for response on the peripheral, given a string UUID. A search is performed to find the characteristic
 */
-(void) ffr_writeCharacteristicWithoutResponseForIdentifier:(NSString*)identifier data:(NSData*)data;

/**
Reads the value of the characteristic on the peripheral, given a string UUID. A search is performed to find the characteristic
 */
-(void) ffr_readCharacteristicWithIdentifier:(NSString*)identifier;

/**
 Subscribes to notifications of values changes on the characteristic on the peripheral, given a string UUID. A search is performed to find the characteristic
 */
-(void) ffr_setNotificationForCharacteristicWithIdentifier:(NSString*)identifier enabled:(BOOL)enable;

/**
 Checks that the characteristic supports notifications on the peripheral, given a string UUID. A search is performed to find the characteristic
 */
-(bool) ffr_isCharacteristicWithIdentifierNotifiable:(NSString*)identifier;

@end


/**
 Compares the NSUUID to a string UUID representation
 */
@interface NSUUID (FFRExtensions)

-(BOOL) ffr_isEqualToString:(NSString*)string;

@end

/**
 Compares the CBUUID to a string UUID representation
 */
@interface CBUUID (FFRExtensions)

-(BOOL) ffr_isEqualToString:(NSString*)string;

@end
