//
//  FFROADHandler.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-13.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FFRPeripheralHandler.h"

/**
 The OAD service UUID as string
 */
extern NSString* const tiOADService;

/**
 Notification for reporting firmware update progress
 */
extern NSString* const FFRProgrammingNotification;

/**
 Key for UserInfo dictionary for state of programming, delivered in NSNumber, intValue
 */
extern NSString* const FFRProgrammingUserInfoStateKey;

/**
 Key for UserInfo dictionary for progress, delivered in NSNumber, floatValue 0..1
 */
extern NSString* const FFRProgrammingUserInfoProgressKey;

/**
 Key for UserInfo dictionary for time left in seconds, delivered in NSNumber, floatValue
 */
extern NSString* const FFRProgrammingUserInfoTimeLeftKey;

/**
 * The state of the firmware programming process.
 */
typedef enum {
	/**
	 The programmer is idle
	 */
	FFRProgrammingStateIdle,

	/**
	 The programmer is busy sending/writing the firmware
	 */
	FFRProgrammingStateWriting,

	/**
	 The programming failed because the device disconnected
	 */
	FFRProgrammingStateFailedDueToDeviceDisconnect,

	/**
	 The programming was completed
	 */
	FFRProgrammingStateWriteCompleted,

	/**
	 The programming was cancelled
	 */
	FFRProgrammingStateCancelRequested
}
FFRProgrammingState;

/**
 Class for handling OAD updates to the case, based on TI OAD examples
 */
@interface FFROADHandler : NSObject<FFRPeripheralHandler>
{
	CBPeripheral* _peripheral;
	BOOL _imageDetected; // TODO: Redundant? Use _currentImageVersion.

	uint16_t _currentImageVersion;
	uint nBlocks;
	uint nBytes;
	uint iBlocks;
	uint iBytes;
	Byte* _dataBuffer;
}

/**
	The current state of the programming process
 */
@property (nonatomic, assign, readonly) FFRProgrammingState state;

/**
 * Called with the image version (A or B).
 */
@property (nonatomic, copy) void (^imageVersionCallback)(char version);

/**
 * Activate the image version service of the case.
 */
- (void) useImageVersionService: (void(^)())serviceAvailableBlock;

/**
 * Ask the case for the current image version (A or B).
 * @return Callback returns 'A' or 'B' in param version on success.
 */
- (void) queryCurrentImageVersion:(void(^)(char version))callback;

/**
	Validates an image and if OK continues with the update.
	NSNotifications are sent to inform on progress
 */
-(BOOL) validateAndLoadImage:(NSData*)data;

@end
