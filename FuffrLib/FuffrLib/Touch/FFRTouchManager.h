//
//  FFRTouchManager.h
//  This is a high-level touch and connection mananger for
//  the FuffrLib.
//
//  Created by Mikael Kindborg on 07/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRBLEManager.h"
#import "FFRCaseHandler.h"

/**
 * Class that provides a high-level interface to the 
 * sensor case library.
 */
@interface FFRTouchManager : NSObject

/** True if a BLE scan is ongoing. */
@property BOOL scanIsOngoing;

/**
 * Connection notification target object and selector.
 * Invoked when connected to the sensor case.
 */
@property (nonatomic, weak) id connectedNotificatonTarget;
@property SEL connectedSuccessSelector;

/** List of touch observers. */
@property NSMutableArray* touchObservers;

/**
 * Public class method that returns singleton instance of 
 * this class.
 */
+ (FFRTouchManager*) sharedManager;

// Public instance methods.

/**
 * Method for connecting to the sensor case.
 * The onSuccess method is called on object
 * when the connection is establised. 
 * Support for the onError method is not yet 
 * implemented (this method is never called).
 */
- (BOOL) connectToSensorCaseNotifying: (id)object
	onSuccess: (SEL)successSelector
	onError: (SEL)errorSelector;

/**
 * Add an object as observer for touch events.
 *
 * @param object The observer that will recieve touch
 * events, as specified by the megthod selectors.
 * @param touchBegan Selector for touch began events.
 * @param touchMoved Selector for touch moved events.
 * @param touchEnded Selector for touch ended events.
 * @param side The side(s) of the case that will be observed.
 *
 * The touchBegan, touchMoved and touchEnded methods
 * have the format:
 *    methodName: (NSSet*) touches
 * where touches is a set of FFRTouch objects.
 * The touch method selectors can be set to nil, in which 
 * case that touch event will not be received.
 *
 * The side can be one of the constants FFRCaseLeft, 
 * FFRCaseRight, FFRCaseTop, and FFRCaseBottom. Multiple 
 * sides can be observed by the same methods by combining
 * the side constants with the bitwise or operator.
 *
 * The most convinient way to monitor different sides of
 * the case is usually to set up different set of methods
 * for each side used by the application.
 */
- (void) addTouchObserver: (id)object
	touchBegan: (SEL)touchBeganSelector
	touchMoved: (SEL)touchMovedSelector
	touchEnded: (SEL)touchEndedSelector
	side: (FFRCaseSide)caseSide;

/**
 * Remove an object as observer for touch events.
 *
 * @param object The observer that will be removed.
 */
- (void) removeTouchObserver: (id)object;

@end
