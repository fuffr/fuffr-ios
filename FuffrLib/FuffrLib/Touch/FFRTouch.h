//
//  FFRTouch.h
//  Class that represents a touch in FuffrLib.
//
//  Created by Christoffer Sjöberg on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRRawTrackingData.h"

/**
 * Type that defines constants for the sides of the case.
 */
typedef enum
{
    /** Touch unknown/not set. */
    FFRCaseNotSet = 0,

    /** Touch tracked along top edge of case. */
    FFRCaseTop = 0x1,

    /** Touch tracked along bottom edge of case. */
    FFRCaseBottom = 0x2,

    /** Touch tracked along left edge of case. */
    FFRCaseLeft = 0x4,

    /** Touch tracked along right edge of case. */
    FFRCaseRight = 0x8
}
FFRCaseSide;

/**
 * Class that encapsulates touch data.
 */
@interface FFRTouch : NSObject

/** 
 * The case side/edge of the touch. 
 */
@property (nonatomic, assign) FFRCaseSide side;

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
 * The touch id. 
 */
@property (nonatomic, assign) NSUInteger identifier;

/** 
 * Touch time stamp. 
 */
@property (nonatomic, assign) NSTimeInterval timestamp;

/** 
 * The phase of the touch: began, moved, ended. 
 */
@property (nonatomic, assign) UITouchPhase phase;

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
