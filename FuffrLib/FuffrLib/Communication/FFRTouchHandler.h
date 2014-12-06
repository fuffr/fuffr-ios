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
#import "FFRTouchHandlerDelegate.h"
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
 * Battery service.
 */
extern NSString* const FFRBatteryServiceUUID;

/**
 * Battery characteristic.
 */
extern NSString* const FFRBatteryCharacteristicUUID;

/**
 * Class that handles BLE touch events.
 */
@interface FFRTouchHandler : NSObject<FFRPeripheralHandler>
{
    // The peripheral.
    CBPeripheral* _peripheral;

	// Current setting for number of touches per side.
	int _numTouchesPerSide;

	// Queue for receiving touch events.
    dispatch_queue_t _touchQueue;

	// Touch events.
    FFRTouch* _touches[32];

	// Timer that handles pruning of old touches.
	NSTimer* _touchPruneTimer;

	// Time after which to remove inactive touches.
	NSTimeInterval _touchRemoveTimeout;
}

/**
 * The delegate object to send touch events to.
 */
@property (nonatomic, weak) id<FFRTouchHandlerDelegate> touchDelegate;

/**
 * The space mapper maps sensor coordinate to screen coordinates.
 */
@property (nonatomic, strong) id<FFRExternalSpaceMapper> spaceMapper;

/**
 * Current device orientation.
 */
@property (atomic, assign) UIInterfaceOrientation userInterfaceOrientation;

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
