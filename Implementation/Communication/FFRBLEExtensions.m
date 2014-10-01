//
//  FFRBLEExtensions.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-28.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRBLEExtensions.h"


@implementation NSUUID (FFRExtensions)

-(BOOL) ffr_isEqualToString:(NSString*)string {
    if (![string length]) {
        return FALSE;
    }

    return [self isEqual:[[NSUUID alloc] initWithUUIDString:string]];
}

@end

@implementation CBUUID (FFRExtensions)

-(BOOL) ffr_isEqualToString:(NSString*)string {
    if (![string length]) {
        return FALSE;
    }

    return [self isEqual:[CBUUID UUIDWithString:string]];
}

@end

@implementation CBService (FFRExtensions)

-(CBCharacteristic*) ffr_characteristicWithIdentifier:(NSString *)identifier {
    //NSLog(@"looking for characteristics in service %@ with count: %d", self.UUID, [self.characteristics count]);
    for (CBCharacteristic *characteristic in self.characteristics) {
        //NSLog(@"characteristic scanned: %@", characteristic.UUID);
        if ([characteristic.UUID ffr_isEqualToString:identifier]) {
            return characteristic;
        }
    }

    return nil;
}

@end

@implementation CBPeripheral (FFRExtensions)

-(CBService*) ffr_serviceWithIdentifier:(NSString *)identifier {
    for (CBService *service in self.services) {
        if ([service.UUID ffr_isEqualToString:identifier]) {
            return service;
        }
    }

    return nil;
}

-(CBCharacteristic*) ffr_characteristicWithIdentifier:(NSString *)identifier {
    for (CBService *service in self.services) {
        //NSLog(@"peripheral service scanned: %@", service.UUID);
        CBCharacteristic* characteristic = [service ffr_characteristicWithIdentifier:identifier];
        if (characteristic != nil) {
            return characteristic;
        }
    }

    return nil;
}

-(CBCharacteristic*) ffr_characteristicWithIdentifier:(NSString *)identifier inService:(NSString *)serviceIdentifier {

    CBService* service = [self ffr_serviceWithIdentifier:serviceIdentifier];
    if (service) {
        return [service ffr_characteristicWithIdentifier:identifier];
    }
    else {
        return nil;
    }
}

-(void) ffr_writeCharacteristicWithIdentifier:(NSString*)identifier data:(NSData*)data {
    CBCharacteristic* characteristic = [self ffr_characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

-(void) ffr_writeCharacteristicWithoutResponseForIdentifier:(NSString*)identifier data:(NSData*)data {
    CBCharacteristic* characteristic = [self ffr_characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

-(void) ffr_readCharacteristicWithIdentifier:(NSString*)identifier {
    CBCharacteristic* characteristic = [self ffr_characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self readValueForCharacteristic:characteristic];
    }
}


-(void) ffr_setNotificationForCharacteristicWithIdentifier:(NSString*)identifier enabled:(BOOL)enable {
    CBCharacteristic* characteristic = [self ffr_characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self setNotifyValue:enable forCharacteristic:characteristic];
    }
}

-(bool) ffr_isCharacteristicWithIdentifierNotifiable:(NSString*)identifier {
    CBCharacteristic* characteristic = [self ffr_characteristicWithIdentifier:identifier];
    if (characteristic.properties & CBCharacteristicPropertyNotify) {
        return TRUE;
    }
    else {
        return FALSE;
    }
}

@end
