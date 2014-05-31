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
	dispatch_queue_t _receiveQueue;
}

/**
	Singleton instance
 */
+(instancetype) sharedManager;

/**
 * Object that recieves BLE data from the connected device.
 */
@property (nonatomic, strong) id handler;

/**
 * Called when a device is discovered.
 */
@property (nonatomic, copy) void (^onPeripheralDiscovered)(CBPeripheral* peripheral);

/**
 * Called when a device is connected.
 */
@property (nonatomic, copy) void (^onPeriperalConnected)(CBPeripheral* peripheral);

/**
 * Called when a device is disconnected.
 */
@property (nonatomic, copy) void (^onPeriperalDisconnected)(CBPeripheral* peripheral);

/**
	Connects a peripheral. Upon connection, the services of the device will be scanned, and any monitored services will also be explored
 */
-(void) connectPeripheral:(CBPeripheral*) peripheral;

/**
	Disconnects the peripheral
 */
-(void) disconnectPeripheral:(CBPeripheral*) peripheral;

/**
 * Get the currently connected device.
 */
- (CBPeripheral*) connectedPeripheral;

/**
 * This method makes sure that the characteristics for the given service
 * are discovered and ready for use.
 */
-(void) useService: (NSString*)serviceUUID
	whenAvailable:(void(^)())serviceAvailableBlock;
	// Original form: whenAvailable:(void(^)(CBService* service, CBPeripheral* hostPeripheral))callback;

/**
	Starts a scan for peripherals, optionally with continuous scanning for RSSI updating e.g.
 */
-(void) startScan:(BOOL)continous;

/**
	Stops scanning for peripherals
 */
-(void) stopScan;

@end
