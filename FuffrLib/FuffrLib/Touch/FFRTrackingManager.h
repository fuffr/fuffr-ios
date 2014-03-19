//
//  FFRTrackingArray.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRTouch.h"

/**
    Notification of new touches
 */
extern NSString* const FFRTrackingBeganNotification;

/**
 Notification of moved touches
 */
extern NSString* const FFRTrackingMovedNotification;

/**
 Notification of ended touches
 */
extern NSString* const FFRTrackingEndedNotification;

/**
 Notification of stationary/existing touches
 */
extern NSString* const FFRTrackingPulsedNotification;

extern const float FFRTrackingManagerUpdateSpeed;

/**
    Class for tracking the touches reported from Fuffr, 
    in order to trigger events for added/removed touches,
    as well as enabling KVO of location in existing touches.
 */
@interface FFRTrackingManager : NSObject {
    NSMutableArray* _trackedObjects;
    NSTimer* _timer;
}

/**
    The current list of tracked touches.
 */
@property (nonatomic, strong) NSArray* trackedObjects;

/**
    Method for processing the reported touches from the sensors
 */
-(void) handleNewOrChangedTrackingObject:(FFRTouch*) data;

@end
