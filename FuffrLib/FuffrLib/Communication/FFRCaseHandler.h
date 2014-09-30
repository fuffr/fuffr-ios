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
#import "FFRTrackingHandler.h"
#import "FFRExternalSpaceMapper.h"

/**
 * Sensor service (used for touch events).
 */
extern NSString* const FFRCaseSensorServiceUUID;

/**
 * Characteristic used to enable sides and set number of touches.
 */
extern NSString* const FFRProximityEnablerCharacteristic;

/**
 * Characteristics that receive notifications.
 */
extern NSString* const FFRTouchCharacteristicUUID1;
extern NSString* const FFRTouchCharacteristicUUID2;
extern NSString* const FFRTouchCharacteristicUUID3;
extern NSString* const FFRTouchCharacteristicUUID4;
extern NSString* const FFRTouchCharacteristicUUID5;

/**
 * Battry service.
 */
extern NSString* const FFRBatteryServiceUUID;

/**
 * Battry characteristic.
 */
extern NSString* const FFRBatteryCharacteristicUUID;

/**
    Main class for handling BLE communication with Fuffr
 */
@interface FFRCaseHandler : NSObject<FFRPeripheralHandler>
{
    // The peripheral
    CBPeripheral* _peripheral;

    // tracks touch data to be able to supply began/ended events
    FFRTrackingHandler* _trackingHandler;

	int _numTouchesPerSide;
	
    dispatch_queue_t _backgroundQueue;
    
    bool _previousTouchDown[32];
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
