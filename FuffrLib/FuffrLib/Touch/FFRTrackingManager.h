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
@interface FFRTrackingManager : NSObject
{
    NSMutableArray* _trackedObjects;
	NSTimer* _timer;
}

/**
    The current list of tracked touches.
 */
@property (nonatomic, strong) NSArray* trackedObjects;

/**
 * Queue used for manipulation of trackedObjects.
 */
@property (nonatomic, weak) dispatch_queue_t backgroundQueue;

/**
 * The timeout value or removing touches that are no longer
 * received from the case. Afterthis timeout, a touch ended
 * event is generated.
 */
@property NSTimeInterval touchRemoveTimeout;

/**
 * Stops timer and deallocates all objects.
 */
- (void) shutDown;

/**
 * Remove all tracked touch objects.
 * This method is useful when resetting Fuffr.
 */
-(void) clearAllTouches;

/**
    Method for processing the reported touches from the sensors
 */
-(void) handleNewOrChangedTrackingObject:(FFRTouch*) touch;

@end
