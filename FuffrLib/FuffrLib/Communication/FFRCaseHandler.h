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
@interface FFRCaseHandler : NSObject<FFRPeripheralHandler>
{
    // The peripheral
    CBPeripheral* _peripheral;

    // tracks touch data to be able to supply began/ended events
    FFRTrackingManager* _trackingManager;
	
    dispatch_queue_t _backgroundQueue;
}

/**
    The space mapper to use to give screen space coordinates from the side sensors
 */
@property (nonatomic, strong) id<FFRExternalSpaceMapper> spaceMapper;

/**
 * Activate the sensor service of the case.
 */
- (void) useSensorService: (void(^)())serviceAvailableBlock;

/**
 * Activate the battery service of the case.
 */
- (void) useBatteryService: (void(^)())serviceAvailableBlock;

/**
 * Tell the tracking manager to remove all touches.
 */
-(void) clearAllTouches;

@end
