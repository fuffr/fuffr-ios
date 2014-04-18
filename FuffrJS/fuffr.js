/**
 * Global object that holds values and functions.
 */
var fuffr = {}

/**
 * Values for sides of the Fuffr case.
 */
fuffr.FFRSideTop = 1
fuffr.FFRSideBottom = 2
fuffr.FFRSideLeft = 4
fuffr.FFRSideRight = 8

/**
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

/**
 * Values for gesture states.
 */
fuffr.FFRGestureRecognizerStateUnknown = 0
fuffr.FFRGestureRecognizerStateBegan = 1
fuffr.FFRGestureRecognizerStateChanged = 2
fuffr.FFRGestureRecognizerStateEnded = 3

/**
 * Counter for native callback ids.
 */
fuffr.callbackIdCounter = 0

/**
 * Table that holds native callback functions.
 */
fuffr.callbackTable = {}

// BEGIN Event functions.

// Assign your own functions to these members.

/**
 * Called when connected to Fuffr.
 */
fuffr.onFuffrConnected = function() {}

/**
 * Called when disconnected from Fuffr.
 */
fuffr.onFuffrDisconnected = function() {}

/**
 * Touch events handlers.
 * touches is an array of touch objects.
 * Touch objects have the following fields:
 * side - side of the touch, one of the FFRSide* values
 * id - touch id
 * x - x coordinate
 * y - y coordinate
 * prevx - previous x coordinate
 * prevy - previous y coordinate
 * normx - normalized x coordinate (decimal number between 0 and 1)
 * normy - normalized y coordinate (decimal number between 0 and 1)
 */
fuffr.onTouchesBegan = function(touches) {}
fuffr.onTouchesMoved = function(touches) {}
fuffr.onTouchesEnded = function(touches) {}

// END Event functions.

/**
 * Set active sides and the number of touches per side.
 * @param sides - you can bit:or side values together, e.g.
 * FFRSideTop | FFRSideLeft | FFRSideRight | FFRSideBottom
 * @param touchesPerSide - the number of touches is the same for all sides
 * @param win - success callback function that takes no parameters
 * @param fail - error callback function that takes no parameters
 */
fuffr.enableSides = function(sides, touchesPerSide, win, fail)
{
	fuffr.callNative(
		'enableSides@' + sides + '@' + touchesPerSide + '@',
		win,
		fail)
}

fuffr.addGesture = function(gestureType, side, callbackFun)
{
	var gestureId = ++fuffr.callbackIdCounter
	fuffr.callbackTable[gestureId] = callbackFun
	fuffr.callNative(
		'addGesture@' + gestureType + '@' + side + '@' + gestureId + '@')
	return gestureId
}

fuffr.removeGesture = function(gestureId)
{
	fuffr.removeCallback(gestureId)
	fuffr.callNative(
		'removeGesture@' + gestureId + '@')
}

fuffr.removeAllGestures = function()
{
	// TODO: Remove all gesture callbacks. Add list to hold ids.
	fuffr.callNative('removeAllGestures@')
}

fuffr.addCallback = function(callbackFun)
{
	var callbackId = ++fuffr.callbackIdCounter
	fuffr.callbackTable[callbackId] = callbackFun
	return callbackId
}

/**
 * Called from JS and native to remove callback.
 */
fuffr.removeCallback = function(callbackId)
{
	delete fuffr.callbackTable[callbackId]
}

/**
 * Called from native to run callback.
 */
fuffr.performCallback = function(callbackId)
{
	var callbackFun = fuffr.callbackTable[callbackId]
	if (callbackFun)
	{
		// Remove the first param, the callbackId.
		var args = Array.prototype.slice.call(arguments)
		args.shift()

		// Call the function.
		callbackFun.apply(null, args)
	}
}

fuffr.callNative = function(command, win, fail)
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

document.addEventListener('DOMContentLoaded', function(event)
{
    //fuffr.callNative('domLoaded@')
})
