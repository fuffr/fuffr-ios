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
#import "FFROADHandler.h"
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
 * Disconnect Fuffr and release the touch manager.
 */
- (void) shutDown;

/**
 * Read characteristics for sensor service.
 * @param serviceAvailableBlock Called when characteristics are available.
 */
- (void) useSensorService: (void(^)())serviceAvailableBlock;

// TODO: Not working yet. Implement support for battery service in case handler.
- (void) useBatteryService: (void(^)())serviceAvailableBlock;

/**
 * Read characteristics for the image version service.
 * @param serviceAvailableBlock Called when characteristics are available.
 */
- (void) useImageVersionService: (void(^)())serviceAvailableBlock;

/**
 * Do an online update the firmware of the Fuffr.
 */
- (void) updateFirmwareFromURL: (NSString*) url;

/**
 * Enable sides of Fuffr.
 * @param sides Sides to enable, bitwise or:ed values 
 * (FFRSideTop, FFRSideLeft, FFRSideRight, FFRSideBottom).
 * @param numberOfTouches Number of touches per side, max 5.
 * 0 means off and puts Fuffr into sleep mode.
 */
- (void) enableSides:(FFRSide)sides touchesPerSide: (NSNumber*)numberOfTouches;

/**
 * Add an object as observer for touch events.
 *
 * @param object The observer that will recieve touch
 * events, as specified by the megthod selectors.
 * @param touchBegan Selector for touch began events.
 * @param touchMoved Selector for touch moved events.
 * @param touchEnded Selector for touch ended events.
 * @param sides The side(s) of Fuffr that will be observed.
 *
 * The touchBegan, touchMoved and touchEnded methods
 * have the format:
 *	methodName: (NSSet*) touches
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
	sides: (FFRSide)sides;

/**
 * Remove an object as observer for touch events.
 *
 * @param object The observer that will be removed.
 */
- (void) removeTouchObserver: (id)object;

/**
 * Add a touch began block at the specified side.
 * @param block Block that is called with the set of touches that began.
 * @param sides The side(s) of Fuffr that will be observed.
 * See documentation of method addTouchObserver for details.
 * @return An identifier that can be used to remove the block.
 */
- (int) addTouchBeganBlock: (void(^)(NSSet* touches))block
	sides: (FFRSide)sides;

/**
 * Add a touch moved block at the specified side.
 * @param block Block that is called with the set of touches that moved.
 * @param sides The side(s) of Fuffr that will be observed.
 * See documentation of method addTouchObserver for details.
 * @return An identifier that can be used to remove the block.
 */
- (int) addTouchMovedBlock: (void(^)(NSSet* touches))block
	sides: (FFRSide)sides;

/**
 * Add a touch ended block at the specified side.
 * @param block Block that is called with the set of touches that ended.
 * @param sides The side(s) of Fuffr that will be observed.
 * See documentation of method addTouchObserver for details.
 * @return An identifier that can be used to remove the block.
 */
- (int) addTouchEndedBlock: (void(^)(NSSet* touches))block
	sides: (FFRSide)sides;

/**
 * Remove a touch block.
 * @param blockId Identifier returned by one of the addTouch*Block methods.
 */
- (void) removeTouchBlock: (int)blockId;

/**
 * Remove all touch observers and touch blocks.
 */
- (void) removeAllTouchObserversAndTouchBlocks;

/**
 Add a gesture recognizer.
 */
-(void) addGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer;

/**
 Remove a gesture recognizer.
 */
-(void) removeGestureRecognizer: (FFRGestureRecognizer*) gestureRecognizer;

/**
 Remove all gesture recognizers.
 */
-(void) removeAllGestureRecognizers;

@end
