//
//  FFRTouchManager.h
//  This is a high-level touch and connection mananger for
//  the FuffrLib.
//
//  Created by Fuffr on 07/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRBLEManager.h"
#import "FFRCaseHandler.h"
#import "FFRGestureRecognizer.h"
#import "FFRLongPressGestureRecognizer.h"
#import "FFRPanGestureRecognizer.h"
#import "FFRPinchGestureRecognizer.h"
#import "FFRRotationGestureRecognizer.h"
#import "FFRSwipeGestureRecognizer.h"
#import "FFRTapGestureRecognizer.h"

/**
 * Class that provides a high-level interface to the 
 * Fuffr library.
 */
@interface FFRTouchManager : NSObject

/**
 * Public class method that returns singleton instance of 
 * this class.
 */
+ (FFRTouchManager*) sharedManager;

// Public instance methods.

/**
 * Set both callbacks for connected and disconnected events
 * in one call.
 */
- (void) onFuffrConnected: (void(^)())connectedBlock
	onFuffrDisconnected: (void(^)())disconnectedBlock;

/**
 * Set callback for connected event.
 */
- (void) onFuffrConnected: (void(^)())connectedBlock;

/**
 * Set callback for disconnected event.
 */
- (void) onFuffrDisconnected: (void(^)())disconnectedBlock;

/**
    Callback when a device is discovered
 */
// TODO: remove
//@property (nonatomic, copy) void(^onPeripheralDiscovery)(CBPeripheral* p);

/**
 * Enable sides of Fuffr.
 * @param sides Sides to enable, bitwise or:ed values 
 * (FFRSideTop, FFRSideLeft, FFRSideRight, FFRSideBottom).
 * @param numberOfTouches Number of touches per side, max 5.
 * 0 means off and puts Fuffr into sleep mode.
 */
- (void) enableSides:(FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches;

/**
 * Disconnect from Fuffr. This saves Fuffr battery.
 * Do this when the app goes to background.
 */
- (void) disconnectFuffr;

/**
 * Reconnect to Fuffr.
 * Do this when the app goes to foreground.
 */
- (void) reconnectFuffr;

/**
 * Add an object as observer for touch events.
 *
 * @param object The observer that will recieve touch
 * events, as specified by the megthod selectors.
 * @param touchBegan Selector for touch began events.
 * @param touchMoved Selector for touch moved events.
 * @param touchEnded Selector for touch ended events.
 * @param side The side(s) of Fuffr that will be observed.
 *
 * The touchBegan, touchMoved and touchEnded methods
 * have the format:
 *    methodName: (NSSet*) touches
 * where touches is a set of FFRTouch objects.
 * The touch method selectors can be set to nil, in which 
 * case that touch event will not be received.
 *
 * The side can be one of the constants FFRLeft,
 * FFRRight, FFRTop, and FFRBottom. Multiple
 * sides can be observed by the same methods by combining
 * the side constants with the bitwise or operator.
 *
 * The most convinient way to monitor different sides of
 * Fuffr is usually to set up different set of methods
 * for each side used by the application.
 */
- (void) addTouchObserver: (id)object
	touchBegan: (SEL)touchBeganSelector
	touchMoved: (SEL)touchMovedSelector
	touchEnded: (SEL)touchEndedSelector
	side: (FFRSide)side;

/**
 * Remove an object as observer for touch events.
 *
 * @param object The observer that will be removed.
 */
- (void) removeTouchObserver: (id)object;

/**
 Add a gesture recognizer.
 */
-(void) addGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer;

/**
 Remove a gesture recognizer.
 */
-(void) removeGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer;

@end
