//
//  FFRBLEManager.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-24.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRBLEManager.h"
#import "FFRBLEExtensions.h"
#import <objc/runtime.h>


@implementation CBPeripheral (discovery)

static void * const kCBDiscoveryRSSIYKey = (void*)&kCBDiscoveryRSSIYKey;

-(void) setDiscoveryRSSI:(NSNumber *)discoveryRSSI {
    if (self.discoveryRSSI == discoveryRSSI) {
        return;
    }
    else {
        objc_setAssociatedObject(self, kCBDiscoveryRSSIYKey, discoveryRSSI, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

-(NSNumber*) discoveryRSSI {
    NSNumber * val = objc_getAssociatedObject(self, kCBDiscoveryRSSIYKey);
    return val;
}

@end


@interface FFRBLEManager ()

-(void) storeDiscoveredPeripheral:(CBPeripheral*) peripheral;

@end

@implementation FFRBLEManager


+(instancetype) sharedManager {
    static dispatch_once_t pred;
    static FFRBLEManager *client = nil;

    dispatch_once(&pred, ^{ client = [[self alloc] init]; });
    return client;
}

-(id) init {
    if (self = [super init]) {
        _receiveQueue = dispatch_queue_create("com.fuffr.receivequeue", nil);

        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.connectedDevices = [NSMutableArray array];
        self.discoveredDevices = [NSMutableArray array];
        _monitoredServiceIdentifiers = [NSMutableDictionary dictionary];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reactivated:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }

    return self;
}

-(void) dealloc {
    //_receiveQueue = nil;

    @try {
        for (CBPeripheral* peripheral in self.connectedDevices) {
            if (peripheral) {
                [_manager cancelPeripheralConnection:peripheral];
            }
        }
    }
    @catch (NSException *exception) {
    }
    @finally {
    }

    [_monitoredServiceIdentifiers removeAllObjects];
    _monitoredServiceIdentifiers = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) reactivated:(NSNotification*) data {
    LOGMETHOD

    if (_manager.state == CBCentralManagerStatePoweredOn) {
        [_bluetoothAlertView dismissWithClickedButtonIndex:0 animated:TRUE];
        _bluetoothAlertView = nil;
    }
}

#pragma mark -

-(void) disconnectPeripheral:(CBPeripheral *)peripheral {
    [_connectedDevices removeObject:peripheral];
    [self.handler deviceDisconnected:peripheral];

    _disconnectedPeripheral = peripheral;
    [_manager cancelPeripheralConnection:peripheral];
}

-(void) connectPeripheral:(CBPeripheral*) peripheral {
    LOGMETHOD

    // store peripheral object to keep reference during connect
    _disconnectedPeripheral = nil;
    peripheral.delegate = self;
    [self.connectedDevices addObject:peripheral];

    //dispatch_async(_receiveQueue, ^{
        [_manager connectPeripheral:peripheral options:nil];
    //});

    [_discoveredDevices removeObject:peripheral];
    [_manager stopScan];
}

-(void) storeDiscoveredPeripheral:(CBPeripheral*) peripheral {
    @synchronized(self.discoveredDevices) {
        BOOL known = FALSE;

        // new or updated?
        for (CBPeripheral*p in self.discoveredDevices) {
            if (p && [[p.identifier UUIDString] compare:[peripheral.identifier UUIDString]] == NSOrderedSame) {
                known = TRUE;
                break;
            }
        }

        // log previous devices due to duplicates appearing
        if (!known) {
            NSLog(@"new device: %@", [peripheral.identifier UUIDString]);
            //for (CBPeripheral* p in self.discoveredDevices) {
                //NSLog(@"known device: %@", p.identifier);
            //}
        }

        // send KVO information
        if (!known) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[self.discoveredDevices count]] forKey:@"discoveredDevices"];
                    [self.discoveredDevices insertObject:peripheral atIndex:[self.discoveredDevices count]];
                    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[self.discoveredDevices count]] forKey:@"discoveredDevices"];
                }
                @catch (NSException *exception) {
                }
                @finally {
                }
            });
        }
        else {
            NSUInteger index = [self.discoveredDevices indexOfObject:peripheral];
            if (index != NSNotFound) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @try {
                        [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"discoveredDevices"];
                        [self.discoveredDevices replaceObjectAtIndex:index withObject:peripheral];
                        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"discoveredDevices"];
                    }
                    @catch (NSException *exception) {
                    }
                    @finally {
                    }
                });
            }
        }
    }
}

-(void) addMonitoredService:(NSString *)serviceIdentifier onDiscovery:(void (^)(CBService *, CBPeripheral* hostPeripheral))callback
{
    [_monitoredServiceIdentifiers setObject:callback forKey:serviceIdentifier];

    for (CBPeripheral* p in self.connectedDevices)
	{
        [p discoverServices:nil];
    }
}

-(void) startScan:(BOOL) continuous
{
    LOGMETHOD

    if (continuous) {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber  numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        [_manager scanForPeripheralsWithServices:nil options:options];
    }
    else {
        [_manager scanForPeripheralsWithServices:nil options:nil];
    }
}

-(void) stopScan {
    [_manager stopScan];
}

#pragma mark - CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSString* errorMessage = nil;

    switch (central.state) {
        case CBCentralManagerStateUnsupported:
            errorMessage = NSLocalizedString(@"The device does not support Bluetooth low energy", @"The device does not support Bluetooth low energy");
            break;
        case CBCentralManagerStateUnauthorized:
            errorMessage = NSLocalizedString(@"The app is not authorized to use Bluetooth low energy", @"The app is not authorized to use Bluetooth low energy");
            break;
        case CBCentralManagerStatePoweredOff:
            errorMessage = NSLocalizedString(@"Bluetooth is currently powered off", @"Bluetooth is currently powered off");
            break;
        default:
            break;
    }

    // if on, start scan
    if (central.state == CBCentralManagerStatePoweredOn)
	{
        [central scanForPeripheralsWithServices:nil options:nil];

        [_bluetoothAlertView dismissWithClickedButtonIndex:0 animated:TRUE];
        _bluetoothAlertView = nil;
    }
    else if (errorMessage) {
        [self.discoveredDevices removeAllObjects];
        _bluetoothAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:errorMessage delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok") otherButtonTitles:nil];
        [_bluetoothAlertView show];
        // NSLocalizedString(@"Ok", @"Ok")
    }
}

-(void)centralManager:(CBCentralManager*) central didDiscoverPeripheral:(CBPeripheral*) peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI {

    NSLog(@"centralManager: Found a BLE device: %@, RSSI: %f", peripheral, [RSSI floatValue]);

    // store discovered device
    peripheral.discoveryRSSI = RSSI;
    [self storeDiscoveredPeripheral:peripheral];

    if ([peripheral.identifier isEqualToString:self.monitoredDeviceIdentifier]) {
        NSLog(@"connecting...");

        if (peripheral.state == CBPeripheralStateDisconnected) {
            [self connectPeripheral:peripheral];
        }
    }

    if (self.onPeripheralDiscovery) {
        self.onPeripheralDiscovery(peripheral);
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    LOGMETHOD

    _disconnectedPeripheral = nil;
    [_discoveredDevices addObject:peripheral];
    dispatch_async(dispatch_get_main_queue(), ^{
        [peripheral discoverServices:nil];
    });
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    LOGMETHOD

    NSLog(@"didDisconnectPeripheral: %@, error: %@", peripheral, error);

    [_connectedDevices removeObject:peripheral];
    [self.handler deviceDisconnected:peripheral];

    if (_disconnectedPeripheral != peripheral) {
        [self performSelector:@selector(connectPeripheral:) withObject:peripheral afterDelay:0.3];
    }
    else {
        _disconnectedPeripheral = nil;
    }

    //[_manager scanForPeripheralsWithServices:nil options:nil];
}

-(void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    LOGMETHOD
    
    [_connectedDevices removeObject:peripheral];
    [_discoveredDevices removeObject:peripheral];
}

#pragma  mark - CBPeripheral delegate

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    LOGMETHOD

    if (error) {
        NSLog(@"peripheral:didDiscoverServices: error %@", error);
    }

    for (CBService *service in peripheral.services) {
        NSLog(@"service found: %@", service.UUID);

        for (NSString* identifier in _monitoredServiceIdentifiers) {
            if ([service.UUID isEqualToString:identifier]) {
                NSLog(@"is monitored service!");

                // discover characteristics for the service
                //dispatch_async(_receiveQueue, ^{
                    [peripheral discoverCharacteristics:nil forService:service];
                //});

                break;
            }
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ %@, error = %@", characteristic.UUID, characteristic, error);
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //NSLog(@"didUpdateValueForCharacteristic %@ %@, error = %@", characteristic.UUID, characteristic, error);

    dispatch_async(_receiveQueue, ^{
        if (!error) {
            [self.handler didUpdateValueForCharacteristic:characteristic];
        }
    });
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ %@, writable: %d, error = %@", characteristic.UUID, characteristic, (characteristic.properties & CBCharacteristicPropertyWrite) > 0, error);

    [self.handler didWriteValueForCharacteristic:characteristic error:error];
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"didDiscoverCharacteristicsForService %@ %@ (%lu), error = %@", service.UUID, service, (unsigned long)[service.characteristics count], error);
    for (CBCharacteristic* c in service.characteristics) {
        NSLog(@"characteristic: %@, %@, %@", c.UUID, c.value, c);
    }

    for (NSString* identifier in _monitoredServiceIdentifiers) {
        if ([service.UUID isEqualToString:identifier]) {
            NSLog(@"monitored service characteristics discovered!");

            void(^callback)(CBService*, CBPeripheral*) = [_monitoredServiceIdentifiers objectForKey:identifier];
            if (callback) {
                callback(service, peripheral);
            }

            break;
        }
    }
}

@end
