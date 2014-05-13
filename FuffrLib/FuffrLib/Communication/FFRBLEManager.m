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
@property (nonatomic, strong) NSMutableArray* serviceRequestQueue;

// Removed discovery KVO mechanism.
//-(void) storeDiscoveredPeripheral:(CBPeripheral*) peripheral;

@end


@implementation FFRBLEManager

+(instancetype) sharedManager
{
	static dispatch_once_t pred;
	static FFRBLEManager *client = nil;

	dispatch_once(&pred, ^{ client = [[self alloc] init]; });
	return client;
}

-(id) init
{
	if (self = [super init])
	{
		_receiveQueue = dispatch_queue_create("com.fuffr.receivequeue", nil);

		_manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
		self.connectedDevices = [NSMutableArray array];
		self.discoveredDevices = [NSMutableArray array];
		self.serviceRequestQueue = [NSMutableArray array];

		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(reactivated:)
			name:UIApplicationDidBecomeActiveNotification
			object:nil];
	}

	return self;
}

-(void) dealloc
{
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

	//[_monitoredServiceIdentifiers removeAllObjects];
	//_monitoredServiceIdentifiers = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) reactivated:(NSNotification*) data
{
	LOGMETHOD

	if (_manager.state == CBCentralManagerStatePoweredOn) {
		[_bluetoothAlertView dismissWithClickedButtonIndex:0 animated:TRUE];
		_bluetoothAlertView = nil;
	}
}

#pragma mark -

-(void) disconnectPeripheral:(CBPeripheral*)peripheral
{
	NSLog(@"FFRBLEManager: App should not call disconnectPeripheral:");
	//assert(NO);

	[_connectedDevices removeObject:peripheral];
	
	// TODO: Called by didDisconnectPeripheral, remove this call.
	//[self.handler deviceDisconnected:peripheral];

	_disconnectedPeripheral = peripheral;
	[_manager cancelPeripheralConnection:peripheral];
}

- (CBPeripheral*) connectedDevice
{
	return [self.connectedDevices firstObject];
}

-(void) connectPeripheral:(CBPeripheral*) peripheral
{
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

// TODO: Is this method ever called?
-(void)discoverServices: (CBPeripheral *)peripheral
{
	LOGMETHOD

	NSLog(@"didConnectPeripheral: %@", peripheral);

	_disconnectedPeripheral = nil;
	[_discoveredDevices addObject:peripheral];

	// Here service discovery is started.
	dispatch_async(dispatch_get_main_queue(), ^{
		[peripheral discoverServices:nil];
	});
}


/* UNUSED CODE
-(void) storeDiscoveredPeripheral:(CBPeripheral*) peripheral
{
	@synchronized(self.discoveredDevices)
	{
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
			//for (CBPeripheral*p in self.discoveredDevices) {
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
*/

-(void) useService: (NSString*)serviceUUID
	whenAvailable:(void(^)())serviceAvailableBlock
{
	// Below, we check if we already have discovered characteristics
	// for the service. If so we directly call the callback block,
	// if not discovery is initiated.

	// Are we connected to a device?
	if ([self.connectedDevices count] > 0)
	{
		// Are services discovered?
		CBPeripheral* device = [self.connectedDevices firstObject];
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
							[[self connectedDevice]
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
			assert(NO);
		}
	}
	else
	{
		// Not valid state, device must have been connected.
		assert(NO);
	}
}

-(void) startScan:(BOOL) continuous
{
	LOGMETHOD

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
		[self.discoveredDevices removeAllObjects];
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
	if ([peripheral.identifier isEqualToString:self.monitoredDeviceIdentifier])
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
	LOGMETHOD

	NSLog(@"didConnectPeripheral: %@", peripheral);

	_disconnectedPeripheral = nil;
	[_discoveredDevices addObject:peripheral];

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
	LOGMETHOD

	NSLog(@"didDisconnectPeripheral: %@, error: %@", peripheral, error);

	[_connectedDevices removeObject:peripheral];
	[self.handler deviceDisconnected:peripheral];

	if (self.onPeriperalDisconnected)
	{
		self.onPeriperalDisconnected(peripheral);
	}

	if (_disconnectedPeripheral != peripheral)
	{
		// In case of shutdown, this seem to work.
		NSLog(@"didDisconnectPeripheral: attempting to reconnect");
		[self performSelector:@selector(connectPeripheral:) withObject:peripheral afterDelay:0.3];
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
	LOGMETHOD

	NSLog(@"didFailToConnectPeripheral: %@, error: %@", peripheral, error);

	[_connectedDevices removeObject:peripheral];
	[_discoveredDevices removeObject:peripheral];
}

#pragma  mark - CBPeripheral delegate

-(void) peripheral:(CBPeripheral *)peripheral
	didDiscoverServices:(NSError *)error
{
	LOGMETHOD

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
	
/* TODO: Remove old code.
	for (CBService *service in peripheral.services)
	{
		NSLog(@"Service discovered: %@", service.UUID);

		for (NSString* identifier in self.monitoredServices)
		{
			if ([service.UUID isEqualToString: identifier])
			{
				NSLog(@"> reading characteristics for service");

				// Note: The dispatch was commented out in the original SensorCaseDemo code.
				// discover characteristics for the service
				//dispatch_async(_receiveQueue, ^{
					// Discover characteristics for the service.
					[peripheral discoverCharacteristics:nil forService:service];
				//});
			}
		}
	}
*/
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
	//NSLog(@"didUpdateValueForCharacteristic %@ %@, error = %@", characteristic.UUID, characteristic, error);

	dispatch_async(_receiveQueue, ^{
		if (!error) {
			[self.handler didUpdateValueForCharacteristic:characteristic];
		}
	});
}

-(void) peripheral:(CBPeripheral *)peripheral
	didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
	error:(NSError *)error
{
	NSLog(@"didWriteValueForCharacteristic %@ %@, writable: %d, error = %@", characteristic.UUID, characteristic, (characteristic.properties & CBCharacteristicPropertyWrite) > 0, error);

	[self.handler didWriteValueForCharacteristic:characteristic error:error];
}

-(void) peripheral:(CBPeripheral *)peripheral
	didDiscoverCharacteristicsForService:(CBService *)service
	error:(NSError *)error
{
	FFRServiceRequestCommand* command;

	// There must be an item in the queue when we get here.
	assert([self.serviceRequestQueue count] > 0);

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
			[[self connectedDevice]
				discoverCharacteristics: nil
				forService: command.service];
		}

	}
}

@end
