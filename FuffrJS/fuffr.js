
/** @namespace */
var fuffr = {}

/*
 * Values for sides of the Fuffr case.
 */
fuffr.FFRSideTop = 1
fuffr.FFRSideBottom = 2
fuffr.FFRSideLeft = 4
fuffr.FFRSideRight = 8

/*
 * Values for gesture types.
 */
fuffr.FFRGesturePan = 1
fuffr.FFRGesturePinch = 2
fuffr.FFRGestureRotate = 3
fuffr.FFRGestureTap = 4
fuffr.FFRGestureDoubleTap = 5
fuffr.FFRGestureLongPress = 6
fuffr.FFRGestureSwipeLeft = 7
fuffr.FFRGestureSwipeRight = 8
fuffr.FFRGestureSwipeUp = 9
fuffr.FFRGestureSwipeDown = 10

/*
 * Values for gesture states.
 */
fuffr.FFRGestureRecognizerStateUnknown = 0
fuffr.FFRGestureRecognizerStateBegan = 1
fuffr.FFRGestureRecognizerStateChanged = 2
fuffr.FFRGestureRecognizerStateEnded = 3

// BEGIN Event functions.

/**
* This object contains funtions that are called by the FuffrBox when different events occur.
* By default, the functions do nothing.
* Replace them with your own functions to handle Fuffr events.
* @namespace
*/
fuffr.on = {}

/**
 * Called when connected to Fuffr.
 * Also called on page load, if Fuffr is already connected.
 */
fuffr.on.connected = function() {}

/**
 * Called when disconnected from Fuffr.
 */
fuffr.on.disconnected = function() {}

/** Information about a touch.
* @typedef {Object} Touch
* @property {number} side - side of the touch, one of the FFRSide* values
* @property {number} id - uniquely identifies the touch
* @property {number} x - raw x coordinate
* @property {number} y - raw y coordinate
* @property {number} prevx - previous raw x coordinate
* @property {number} prevy - previous raw y coordinate
* @property {number} normx - normalized x coordinate (a real number between 0 and 1)
* @property {number} normy - normalized y coordinate (a real number between 0 and 1)
*/

/**
* Called when one or more new touches has been detected.
* @param {Array} touches - Array of the new {@link Touch} objects.
*/
fuffr.on.touchesBegan = function(touches) {}

/**
* Called when one or more touches have moved.
* @param {Array} touches - Array of {@link Touch} objects.
*/
fuffr.on.touchesMoved = function(touches) {}

/**
* Called when one or more touches have ended.
* @param {Array} touches - Array of the ended {@link Touch} objects.
*/
fuffr.on.touchesEnded = function(touches) {}

// END Event functions.

// BEGIN hide local variables.
(function() {
// Counter for native callback ids.
var callbackIdCounter = 0

// Table that holds native callback functions.
var callbackTable = {}

// Holder object for internal functions. Do not use.
fuffr.internal = {}

/**
* Set active sides and the number of touches per side.
* @param {number} sides - you can bit:or side values together, e.g.
* FFRSideTop | FFRSideLeft | FFRSideRight | FFRSideBottom
* Can also be set to 0, to disable all sides.
* @param touchesPerSide - the number of touches is the same for all sides
* @param win - success callback function that takes no parameters
* @param fail - error callback function that takes no parameters
*/
fuffr.enableSides = function(sides, touchesPerSide, win, fail)
{
	fuffr.internal.callNative(
		'enableSides@' + sides + '@' + touchesPerSide + '@',
		win,
		fail)
}

/** Add a gesture recognizer.
* @param {number} gestureType - one of the FFRGesture constants.
* @param {number} sides - one or more of the FFRSide constants.
* @param {function} callback - a function that will be called when the gesture is recognized.
* The parameters in the callback vary depending on gestureType.
* The callback takes one of these forms: panCallback(), pinchCallback(), rotateCallback() or gestureCallback()
* @returns {number} gestureId - identifies the gesture that was just added. Pass this value to removeGesture().
*/
fuffr.addGesture = function(gestureType, sides, callback)
{
	var gestureId = ++callbackIdCounter
	callbackTable[gestureId] = callback
	fuffr.internal.callNative(
		'addGesture@' + gestureType + '@' + sides + '@' + gestureId + '@')
	return gestureId
}

/** This function is a parameter to addGesture() with FFRGesturePan and is called when the state of the gesture changes.
* @callback panCallback
* @param {number} state - one of the FFRGestureRecognizerState constants.
* @param {number} x - relative to the start point.
* @param {number} y - relative to the start point.
*/

/** This function is a parameter to addGesture() with FFRGesturePinch and is called when the state of the gesture changes.
* @callback pinchCallback
* @param {number} state - one of the FFRGestureRecognizerState constants.
* @param {number} scale - distance between the pinching points. Starts at 1.0.
*/

/** This function is a parameter to addGesture() with FFRGestureRotate and is called when the state of the gesture changes.
* @callback rotateCallback
* @param {number} state - one of the FFRGestureRecognizerState constants.
* @param {number} rotation - in radians, relative to the starting angle.
*/

/** This function is a parameter to addGesture() with
* FFRGestureTap, FFRGestureDoubleTap, FFRGestureLongPress or FFRGestureSwipeLeft.
* It is called when the state of the gesture changes.
* @callback gestureCallback
* @param {number} state - one of the FFRGestureRecognizerState constants.
*/

/** Remove a gesture recognizer.
* @param {number} gestureId - identifies the gesture to be removed. It is the return value from a previous call to addGesture().
*/
fuffr.removeGesture = function(gestureId)
{
	fuffr.internal.removeCallback(gestureId)
	fuffr.internal.callNative(
		'removeGesture@' + gestureId + '@')
}

/** Remove all gesture recognizers.
*/
fuffr.removeAllGestures = function()
{
	// TODO: Remove all gesture callbacks. Add list to hold ids.
	fuffr.internal.callNative('removeAllGestures@')
}

fuffr.internal.addCallback = function(callbackFun)
{
	var callbackId = ++callbackIdCounter
	callbackTable[callbackId] = callbackFun
	return callbackId
}

/**
 * Called from JS and native to remove callback.
 */
fuffr.internal.removeCallback = function(gestureId)
{
	delete callbackTable[gestureId]
}

/**
 * Called from native to run callback.
 */
fuffr.internal.performCallback = function(gestureId)
{
	var callbackFun = callbackTable[gestureId]
	if (callbackFun)
	{
		// Remove the first param, the callbackId.
		var args = Array.prototype.slice.call(arguments)
		args.shift()

		// Call the function.
		callbackFun.apply(null, args)
	}
}

fuffr.internal.callNative = function(command, win, fail)
{
	var request = new XMLHttpRequest()
	request.open('get', 'fuffr-bridge@' + command);
	request.onreadystatechange = function()
	{
		if (request.readyState === 4)
		{
			// 200 is a successful return
			if (request.status === 200)
			{
				win && win(request.responseText)
			}
			else
			{
				fail && fail(request.status)
			}
		}
	}
	request.send()
}

// END hide local variables.
})()

document.addEventListener('DOMContentLoaded', function(event)
{
	fuffr.callNative('domLoaded@')
})
