//
//  FFRBLEExtensions.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-28.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRBLEExtensions.h"


@implementation NSUUID (FFRExtensions)

-(BOOL) isEqualToString:(NSString*)string {
    if (![string length]) {
        return FALSE;
    }

    return [self isEqual:[[NSUUID alloc] initWithUUIDString:string]];
}

@end

@implementation CBUUID (FFRExtensions)

-(BOOL) isEqualToString:(NSString*)string {
    if (![string length]) {
        return FALSE;
    }

    return [self isEqual:[CBUUID UUIDWithString:string]];
}

@end

@implementation CBService (FFRExtensions)

-(CBCharacteristic*) characteristicWithIdentifier:(NSString *)identifier {
    //NSLog(@"looking for characteristics in service %@ with count: %d", self.UUID, [self.characteristics count]);
    for (CBCharacteristic *characteristic in self.characteristics) {
        //NSLog(@"characteristic scanned: %@", characteristic.UUID);
        if ([characteristic.UUID isEqualToString:identifier]) {
            return characteristic;
        }
    }

    return nil;
}

@end

@implementation CBPeripheral (FFRExtensions)

-(CBService*) serviceWithIdentifier:(NSString *)identifier {
    for (CBService *service in self.services) {
        if ([service.UUID isEqualToString:identifier]) {
            return service;
        }
    }

    return nil;
}

-(CBCharacteristic*) characteristicWithIdentifier:(NSString *)identifier {
    for (CBService *service in self.services) {
        //NSLog(@"peripheral service scanned: %@", service.UUID);
        CBCharacteristic* characteristic = [service characteristicWithIdentifier:identifier];
        if (characteristic != nil) {
            return characteristic;
        }
    }

    return nil;
}

-(CBCharacteristic*) characteristicWithIdentifier:(NSString *)identifier inService:(NSString *)serviceIdentifier {

    CBService* service = [self serviceWithIdentifier:serviceIdentifier];
    if (service) {
        return [service characteristicWithIdentifier:identifier];
    }
    else {
        return nil;
    }
}

-(void) writeCharacteristicWithIdentifier:(NSString*)identifier data:(NSData*)data {
    CBCharacteristic* characteristic = [self characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

-(void) writeCharacteristicWithoutResponseForIdentifier:(NSString*)identifier data:(NSData*)data {
    CBCharacteristic* characteristic = [self characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

-(void) readCharacteristicWithIdentifier:(NSString*)identifier {
    CBCharacteristic* characteristic = [self characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self readValueForCharacteristic:characteristic];
    }
}


-(void) setNotificationForCharacteristicWithIdentifier:(NSString*)identifier enabled:(BOOL)enable {
    CBCharacteristic* characteristic = [self characteristicWithIdentifier:identifier];
    if (characteristic) {
        [self setNotifyValue:enable forCharacteristic:characteristic];
    }
}

-(bool) isCharacteristicWithIdentifierNotifiable:(NSString*)identifier {
    CBCharacteristic* characteristic = [self characteristicWithIdentifier:identifier];
    if (characteristic.properties & CBCharacteristicPropertyNotify) {
        return TRUE;
    }
    else {
        return FALSE;
    }
}

@end
