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

	//NSMutableDictionary* _monitoredServiceIdentifiers;

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
 * Device UUID, if a matching device is found, it will be autoconnected.
 */
@property (nonatomic, copy) NSString* monitoredDeviceIdentifier;

/**
 * List of discovered devices.
 */
@property (nonatomic, strong) NSMutableArray* discoveredDevices;

/**
 * List of connected devices. This is currently limited to one device.
 */
@property (nonatomic, strong) NSMutableArray* connectedDevices;

/**
 * UUID stringss of monitored services.
 */
@property (nonatomic, strong) NSMutableDictionary* monitoredServices;

/**
 * Called when a device is discovered.
 */
@property (nonatomic, copy) void (^onPeripheralDiscovered)(CBPeripheral* peripheral);

/**
 * Called when a device is disconnected.
 */
@property (nonatomic, copy) void (^onPeriperalDisconnected)(CBPeripheral* peripheral);

/**
 * Add a service UUID and a block that will be called when the characteristics
 * of the given service are discovered. Add monitored services early on at
 * program startup. If added after connecting to the device, the callback
 * will not be called, decause services discovery is made in didConnectPeriperal.
 */
-(void) addMonitoredService: (NSString*)serviceUUID
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
