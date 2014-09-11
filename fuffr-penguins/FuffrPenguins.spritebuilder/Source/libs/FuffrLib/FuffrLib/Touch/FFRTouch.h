//
//  FFRTouch.h
//  Class that represents a touch in FuffrLib.
//
//  Created by Fuffr on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRRawTrackingData.h"

/**
 * Type that defines constants for the states of a touch.
 */
typedef enum
{
	FFRTouchPhaseBegan = 1,
	FFRTouchPhaseMoved = 2,
	FFRTouchPhaseEnded = 4
}
FFRTouchPhase;

/**
 * Type that defines constants for the sides Fuffr.
 */
typedef enum
{
	/** Touch unknown/not set. */
	FFRSideNotSet = 0,

	/** Touch tracked along top edge. */
	FFRSideTop = 0x1,

	/** Touch tracked along bottom edge. */
	FFRSideBottom = 0x2,

	/** Touch tracked along left edge. */
	FFRSideLeft = 0x4,

	/** Touch tracked along right edge. */
	FFRSideRight = 0x8
}
FFRSide;

/**
 * Class that encapsulates touch data.
 */
@interface FFRTouch : NSObject

/** 
 * The touch id. 
 */
@property (nonatomic, assign) NSUInteger identifier;

/** 
 * The side/edge of the touch.
 */
@property (nonatomic, assign) FFRSide side;

/** 
 * Raw position data value from the sensor. 
 */
@property (nonatomic, assign) CGPoint rawPoint;

/** 
 * Position value normalized to max values (x, y) of the sensor. 
 * Normalized coordinates are in the interval 0..1.
 */
@property (nonatomic, assign) CGPoint normalizedLocation;

/**
 * Touch time stamp. 
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/** 
 * The event type of the touch.
 */
@property (nonatomic, assign) FFRTouchPhase phase;

/** 
 * The point on the screen, as determined by a
 * <FFRExternalSpaceMapper> object.
 */
@property (nonatomic, assign) CGPoint location;

/**
 * The previous location of the touch.
 */
@property (nonatomic, assign, readonly) CGPoint previousLocation;

@end
