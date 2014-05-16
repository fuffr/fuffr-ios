//
//  FFRCaseHandler.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FFRPeripheralHandler.h"
#import "FFRTouch.h"
#import "FFRTrackingManager.h"
#import "FFRExternalSpaceMapper.h"

/**
 The identifier of the Fuffr BLE service
 */
extern NSString* const FFRCaseSensorServiceUUID;

/**
 Characteristic to enable Fuffr
 */
extern NSString* const FFRProximityEnablerCharacteristic;

/**
 Characteristic to receive notifications of values from left side
 */
extern NSString* const FFRSideLeftUUID;

/**
 Characteristic to receive notifications of values from bottom side
 */
extern NSString* const FFRSideBottomUUID;

/**
 Characteristic to receive notifications of values from right side
 */
extern NSString* const FFRSideRightUUID;

/**
 Characteristic to receive notifications of values from top side
 */
extern NSString* const FFRSideTopUUID;

extern NSString* const FFRBatteryServiceUUID;

extern NSString* const FFRBatteryCharacteristicUUID;

/**
    Main class for handling BLE communication with Fuffr
 */
@interface FFRCaseHandler : NSObject {
    // The peripheral
    CBPeripheral* _peripheral;

    // tracks touch data to be able to supply began/ended events
    FFRTrackingManager* _touches;
	
    dispatch_queue_t _backgroundQueue;
}

/**
    The space mapper to use to give screen space coordinates from the side sensors
 */
@property (nonatomic, strong) id<FFRExternalSpaceMapper> spaceMapper;

-(void) setPeripheral:(CBPeripheral*) peripheral;

- (void) useSensorService: (void(^)())serviceAvailableBlock;

- (void) useBatteryService: (void(^)())serviceAvailableBlock;

/**
 * Called when notifyable characteristics update their values.
 */
-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;

/**
 * Callback when writing to characteristics (if not requesting write with no response).
 */
-(void) didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

/**
 * The device was disconnected.
 */
-(void) deviceDisconnected:(CBPeripheral *)peripheral;

/**
 * Tell the tracking manager to remove all touches.
 */
-(void) clearAllTouches;

@end
