//
//  FFRCaseHandler.h
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-18.
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
extern NSString* const FFRCaseSensorServiceUuid;

/**
 Characteristic to enable the Fuffr sensor case
 */
extern NSString* const FFRProximityEnablerCharacteristic;

/**
 Characteristic to receive notifications of values from left side
 */
extern NSString* const FFRSideLeftUdid;

/**
 Characteristic to receive notifications of values from bottom side
 */
extern NSString* const FFRSideBottomUdid;

/**
 Characteristic to receive notifications of values from right side
 */
extern NSString* const FFRSideRightUdid;

/**
 Characteristic to receive notifications of values from top side
 */
extern NSString* const FFRSideTopUdid;


/**
    Main class for handling BLE communication with the Fuffr iPhone sensor case
 */
@interface FFRCaseHandler : NSObject<FFRPeripheralHandler> {
    // The peripheral
    CBPeripheral* _peripheral;

    // tracks touch data to be able to supply began/ended events
    FFRTrackingManager* _touches;
    dispatch_queue_t _backgroundQueue;
}

/**
    Initializes the handler for the device, tries to enable the sensors and subscribe to the characteristics
 */
-(instancetype) initWithPeripheral:(CBPeripheral*)peripheral;

/**
    The space mapper to use to give screen space coordinates from the side sensors
 */
@property (nonatomic, strong) id<FFRExternalSpaceMapper> spaceMapper;

@end
