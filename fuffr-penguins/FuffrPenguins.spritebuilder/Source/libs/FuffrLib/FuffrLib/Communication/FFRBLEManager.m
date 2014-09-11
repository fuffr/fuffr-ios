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

@interface FFRServiceRequestCommand : NSObject
@property (weak, nonatomic) CBService* service;
@property (strong, nonatomic) void (^block)();
@end

@implementation FFRServiceRequestCommand
@end


@implementation CBPeripheral (discovery)

static void * const kCBDiscoveryRSSIYKey = (void*)&kCBDiscoveryRSSIYKey;

-(void) setDiscoveryRSSI:(NSNumber *)discoveryRSSI
{
	if (self.discoveryRSSI == discoveryRSSI) {
		return;
	}
	else {
		objc_setAssociatedObject(self, kCBDiscoveryRSSIYKey, discoveryRSSI, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
}

-(NSNumber*) discoveryRSSI
{
	NSNumber * val = objc_getAssociatedObject(self, kCBDiscoveryRSSIYKey);
	return val;
}

@end


@interface FFRBLEManager ()

/**
 * Device UUID, if a matching device is found, it will be autoconnected.
 */
@property (nonatomic, copy) NSString* monitoredPeripheralIdentifier;

/**
 * List of discovered devices.
 */
@property (nonatomic, strong) NSMutableArray* discoveredPeripherals;

/**
 * List of connected devices. This is currently limited to one device.
 */
@property (nonatomic, strong) NSMutableArray* connectedPeripherals;

/**
 * UUID stringss of monitored services.
 */
@property (nonatomic, strong) NSMutableArray* serviceRequestQueue;

@end


@implementation FFRBLEManager

#pragma mark - Singleton

+(instancetype) sharedManager
{
	static dispatch_once_t pred;
	static FFRBLEManager *client = nil;

	dispatch_once(&pred, ^{ client = [[self alloc] init]; });
	return client;
}

#pragma mark - init/dealloc

-(id) init
{
	if (self = [super init])
	{
		_receiveQueue = dispatch_queue_create("com.fuffr.receivequeue", nil);

		_manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
		self.connectedPeripherals = [NSMutableArray array];
		self.discoveredPeripherals = [NSMutableArray array];
		self.serviceRequestQueue = [NSMutableArray array];
	}

	return self;
}

-(void) dealloc
{
	//_receiveQueue = nil;

	@try {
		for (CBPeripheral* peripheral in self.connectedPeripherals) {
			if (peripheral) {
				[_manager cancelPeripheralConnection:peripheral];
			}
		}
	}
	@catch (NSException *exception) {
	}
	@finally {
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) reactivated:(NSNotification*) data
{
	if (_manager.state == CBCentralManagerStatePoweredOn) {
		[_bluetoothAlertView dismissWithClickedButtonIndex:0 animated:TRUE];
		_bluetoothAlertView = nil;
	}
}

#pragma mark - Connect/disconnect

-(void) disconnectPeripheral:(CBPeripheral*)peripheral
{
	NSLog(@"FFRBLEManager: App called disconnectPeripheral:");

	[_connectedPeripherals removeObject:peripheral];

	_disconnectedPeripheral = peripheral;
	[_manager cancelPeripheralConnection:peripheral];
}

- (CBPeripheral*) connectedPeripheral
{
	return [self.connectedPeripherals firstObject];
}

-(void) connectPeripheral:(CBPeripheral*) peripheral
{
	// store peripheral object to keep reference during connect
	_disconnectedPeripheral = nil;
	peripheral.delegate = self;

	[self.connectedPeripherals addObject:peripheral];

	// TODO:
	// Here the main queue should be used if async is needed.
	//dispatch_async(_receiveQueue,
	dispatch_async(dispatch_get_main_queue(),
	^{
		[_manager connectPeripheral:peripheral options:nil];
	});

	[_discoveredPeripherals removeObject:peripheral];
	[_manager stopScan];
}

#pragma mark - Service discovery

// TODO: Is this method ever called?
-(void)discoverServices: (CBPeripheral *)peripheral
{
	NSLog(@"didConnectPeripheral: %@", peripheral);

	_disconnectedPeripheral = nil;
	[_discoveredPeripherals addObject:peripheral];

	// Here service discovery is started.
	dispatch_async(dispatch_get_main_queue(), ^{
		[peripheral discoverServices:nil];
	});
}

-(void) useService: (NSString*)serviceUUID
	whenAvailable:(void(^)())serviceAvailableBlock
{
	// Below, we check if we already have discovered characteristics
	// for the service. If so we directly call the callback block,
	// if not discovery is initiated.

	// Are we connected to a device?
	if ([self.connectedPeripherals count] > 0)
	{
		// Are services discovered?
		CBPeripheral* device = [self.connectedPeripherals firstObject];
		if (device.services)
		{
			// Find service.
			for (CBService* service in device.services)
			{
				if ([service.UUID isEqualToString: serviceUUID])
				{
					// Do we have the characteristics for the service?
					if (service.characteristics)
					{
						NSLog(@"Service already availabe");
						
						// Characteristics are already discovered, call callback.
						serviceAvailableBlock();

						break;
					}
					else
					{
						NSLog(@"Service characteristics need to be discovered");

						// Add to queue.
						// Discover characteristics if queue length is 1.
						// Do queue manipulation on main thread.
						// In didDiscoverCharacteristics, check queue, call callback,
						// call discoverCharacteristics again for next service
						// if queue is not empty.
						
						// Create command object.
						FFRServiceRequestCommand* command = [FFRServiceRequestCommand new];
						command.service = service;
						command.block = serviceAvailableBlock;
						[self.serviceRequestQueue addObject: command];

						// Discover characteristics now if queue length is 1.
						if (1 == [self.serviceRequestQueue count])
						{
							[[self connectedPeripheral]
								discoverCharacteristics: nil
								forService: service];
						}

						break;
					}
				}
			}
		}
		else
		{
			// Not valid state, services must have been discovered.
			NSLog(@"useService: Services not discovered");
		}
	}
	else
	{
		// Not valid state, device must have been connected.
		NSLog(@"useService: Device not connected");
	}
}

#pragma mark - Scan (not called?)

-(void) startScan:(BOOL) continuous
{
	if (continuous) {
		NSDictionary *options = [NSDictionary
			dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool:YES],
				CBCentralManagerScanOptionAllowDuplicatesKey,
				nil];
		[_manager scanForPeripheralsWithServices:nil options:options];
	}
	else {
		[_manager scanForPeripheralsWithServices:nil options:nil];
	}
}

-(void) stopScan
{
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
		// This is where scanning is started.
		[central scanForPeripheralsWithServices:nil options:nil];
		NSLog(@"*** Scan started in centralManagerDidUpdateState");
		[_bluetoothAlertView dismissWithClickedButtonIndex:0 animated:TRUE];
		_bluetoothAlertView = nil;
	}
	else if (errorMessage)
	{
		[self.discoveredPeripherals removeAllObjects];
		_bluetoothAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:errorMessage delegate:self cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok") otherButtonTitles:nil];
		[_bluetoothAlertView show];
		// NSLocalizedString(@"Ok", @"Ok")
	}
}

-(void)centralManager:(CBCentralManager*) central
	didDiscoverPeripheral:(CBPeripheral*) peripheral
	advertisementData:(NSDictionary*)advertisementData
	RSSI:(NSNumber*)RSSI
{
	//NSLog(@"centralManager: Found a BLE device: %@, RSSI: %f", peripheral, [RSSI floatValue]);

	// store discovered device
	peripheral.discoveryRSSI = RSSI;

	// This method sends KVO notification "discoveredDevices".

	//[self storeDiscoveredPeripheral:peripheral];
	
	// Note: Above commented out beause maintaining a list and notifying observers
	// just adds complexity! KVO was probably used with the list UI in SensorCaseDemo,
	// and this is not needed in the current library.

	// Here connect seems to be made to a known device. If this is done,
	// observers of discovery should not be notified !?
	// TODO: Investigate and fix.
	if ([peripheral.identifier isEqualToString:self.monitoredPeripheralIdentifier])
	{
		NSLog(@"centralManager:didDiscoverPeripheral: connecting to monitored device...");

		if (peripheral.state == CBPeripheralStateDisconnected)
		{
			[self connectPeripheral:peripheral];
		}
	}

	// Use this mechanism to monitor discovered devices rather than the KVO model.
	if (self.onPeripheralDiscovered)
	{
		self.onPeripheralDiscovered(peripheral);
	}
}

-(void)centralManager:(CBCentralManager *)central
	didConnectPeripheral:(CBPeripheral *)peripheral
{
	NSLog(@"didConnectPeripheral: %@", peripheral);

	_disconnectedPeripheral = nil;
	[_discoveredPeripherals addObject:peripheral];

	// Here service discovery is started.
	dispatch_async(dispatch_get_main_queue(), ^{
		[peripheral discoverServices:nil];
	});
}

// TODO: Find out how reconnect of disconnected peripheral works.
-(void) centralManager:(CBCentralManager *)central
	didDisconnectPeripheral:(CBPeripheral *)peripheral
	error:(NSError *)error
{
	NSLog(@"didDisconnectPeripheral: %@, error: %@", peripheral, error);

	[_connectedPeripherals removeObject:peripheral];

	if (self.handler)
	{
		[self.handler peripheralDisconnected: peripheral];
	}

	if (self.onPeriperalDisconnected)
	{
		self.onPeriperalDisconnected(peripheral);
	}

	if (_disconnectedPeripheral != peripheral)
	{
		// In case of shutdown, this seem to work.
		NSLog(@"didDisconnectPeripheral: attempting to reconnect");
		[self performSelector:@selector(connectPeripheral:) withObject:peripheral afterDelay:0.5];
	}
	else
	{
		NSLog(@"didDisconnectPeripheral: NOT attempting to connect");
		_disconnectedPeripheral = nil;
	}

	// I guess the above mechanism of calling connectPeripheral is used
	// rather than scanning again. Note that connectPeripheral does not time out.
	//[_manager scanForPeripheralsWithServices:nil options:nil];
}

-(void) centralManager:(CBCentralManager *)central
	didFailToConnectPeripheral:(CBPeripheral *)peripheral
	error:(NSError *)error
{
	NSLog(@"didFailToConnectPeripheral: %@, error: %@", peripheral, error);

	[_connectedPeripherals removeObject:peripheral];
	[_discoveredPeripherals removeObject:peripheral];
}

#pragma mark - CBPeripheral delegate

-(void) peripheral:(CBPeripheral *)peripheral
	didDiscoverServices:(NSError *)error
{
	if (error)
	{
		NSLog(@"peripheral:didDiscoverServices: error %@", error);

		// TODO: Disconnect the device and call onPeriperalDiconnected callback?

		return;
	}

	// Once services are read, we notify the connected callback.
	// The app can now request to read characteristics for services.
	if (self.onPeriperalConnected)
	{
		self.onPeriperalConnected(peripheral);
	}
}

-(void) peripheral:(CBPeripheral *)peripheral
	didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
	error:(NSError *)error
{
	//NSLog(@"didUpdateNotificationStateForCharacteristic %@ %@, error = %@", characteristic.UUID, characteristic, error);
}

-(void) peripheral:(CBPeripheral *)peripheral
	didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
	error:(NSError *)error
{
	//NSLog(@"didUpdateValueForCharacteristic 1: %@ %@, error: %@", characteristic.UUID, characteristic, error);

	// The purpose of the receive queue could be to read notifications
	// as quickly as possible.
	dispatch_async(_receiveQueue, ^{
		if (!error && self.handler) {
			[self.handler didUpdateValueForCharacteristic:characteristic];
		}
	});
}

-(void) peripheral:(CBPeripheral *)peripheral
	didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
	error:(NSError *)error
{
	//NSLog(@"didWriteValueForCharacteristic %@ %@, writable: %d, error = %@", characteristic.UUID, characteristic, (characteristic.properties & CBCharacteristicPropertyWrite) > 0, error);

	if (self.handler)
	{
		[self.handler didWriteValueForCharacteristic:characteristic error:error];
	}
}

-(void) peripheral:(CBPeripheral *)peripheral
	didDiscoverCharacteristicsForService:(CBService *)service
	error:(NSError *)error
{
	FFRServiceRequestCommand* command;

	// Get service request from the queue.
	if ([self.serviceRequestQueue count] > 0)
	{
		command = [self.serviceRequestQueue objectAtIndex: 0];
		[self.serviceRequestQueue removeObjectAtIndex: 0];

		// Call callback block.
		command.block();

		// If there is another item in the queue, discover next service.
		if ([self.serviceRequestQueue count] > 0)
		{
			command = [self.serviceRequestQueue objectAtIndex: 0];
			[[self connectedPeripheral]
				discoverCharacteristics: nil
				forService: command.service];
		}

	}
}

@end
