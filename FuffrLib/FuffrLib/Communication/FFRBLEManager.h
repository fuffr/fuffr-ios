//
//  FFRBLEManager.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-24.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FFRPeripheralHandler.h"


/**
 Category to be able to write RSSI updates when continuous device discovery is enabled
 */
@interface CBPeripheral (discovery)

/**
    The signal strength that is continuously reported during device discovery. For KVO observation
 */
@property (nonatomic, retain) NSNumber* discoveryRSSI;

@end

/**
    Main Bluetooth Low Energy manager. Handles basic house keeping tasks, delegates actual device communication to FFRPeripheralHandler
 */
@interface FFRBLEManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager* _manager;
    CBPeripheral* _disconnectedPeripheral;
    UIAlertView* _bluetoothAlertView;

    NSMutableDictionary* _monitoredServiceIdentifiers;

    dispatch_queue_t _receiveQueue;
}

/**
    Singleton instance
 */
+(instancetype) sharedManager;

/**
    Handler for working with the connected peripheral.
 */
@property (nonatomic, strong) id<FFRPeripheralHandler> handler;

/**
    Device UUID, if a matching device is found, it will be autoconnected
 */
@property (nonatomic, copy) NSString* monitoredDeviceIdentifier;

/**
    List of discovered devices
 */
@property (nonatomic, strong) NSMutableArray* discoveredDevices;

/**
    List of connected devices. Due to the handlers single peripheral awareness, this is in essence limited to 1
	TODO: "is in essence" should be "is" !!
 */
@property (nonatomic, strong) NSMutableArray* connectedDevices;

/**
    Callback when a device is discovered
 */
@property (nonatomic, copy) void(^onPeripheralDiscovery)(CBPeripheral* p);

/**
 Adds a service UUID that corresponding characteristics will be auto discovered on, as well as callback for working with the discovered service
 */
-(void) addMonitoredService:(NSString*) serviceIdentifier
	onDiscovery:(void(^)(CBService* service, CBPeripheral* hostPeripheral))callback;

/**
    Connects a peripheral. Upon connection, the services of the device will be scanned, and any monitored services will also be explored
 */
-(void) connectPeripheral:(CBPeripheral*) peripheral;

/**
    Disconnects the peripheral
 */
-(void) disconnectPeripheral:(CBPeripheral*) peripheral;

/**
    Starts a scan for peripherals, optionally with continuous scanning for RSSI updating e.g.
 */
-(void) startScan:(BOOL)continous;

/**
    Stops scanning for peripherals
 */
-(void) stopScan;

@end
