# Fuffr JavaScript Tutorial

This tutorial explains how to develop apps for Fuffr using JavaScript.

## Introduction

Fuffr JavaScript apps are standard HTML5 apps, with the addition that that can read sensor input. Fuffr apps run inside FuffrBox, an iOS app that is like a web browser for Fuffr. FuffrBox has bindings from JavaScript to native code that reads the sensors.

## What you need

To develop JavaScript apps for Fuffr, you need:

* Basic knowledge of HTML5/JavaScript development.
* An iPhone 5/5C/5S running iOS 7 or higher. (You can also use iPhone 4S, but Fuffr is designed for the iPhone 5 form factor.)
* The FuffrBox app installed on your iPhone.
* Fuffr hardware (contact hello@fuffr.com for information on availability).

## Get the JavaScript source code

The library needed for interacting with Fuffr is in the file [fuffr.js](https://github.com/fuffr/fuffr-ios/blob/master/FuffrJS/lib/fuffr.js).

An easy example to get started with is the [Dancing Squares](https://github.com/fuffr/fuffr-ios/blob/master/FuffrJS/dancing-squares.html) demo.

## Run the example apps

When you launch FuffrBox you are presented with demo apps you can run right away. The source code for these apps are found on [GitHub](https://github.com/fuffr/fuffr-ios/tree/master/FuffrJS).

To run your own code, do as follows:

* Put the files needed for your example on a webserver (e.g. mygame.html and fuffr.js)
* Enter the URL to your game in the address field in FuffrBox
* Press the "Go" button next to the URL field

The workflow when developing is:

* Edit your code
* Upload to webserver if you don't run a local server
* Press "Go" to reload


## The Fuffr JavaScript Touch API

### Basic principles

The API is based on a number of functions that are called when touch events and connection events occur.

All of the Fuffr API is in the global object **fuff**.

The API is documented in the documentation comments in [fuffr.js](https://github.com/fuffr/fuffr-ios/blob/master/FuffrJS/lib/fuffr.js).

### Connection events and enabling Fuffr

Fuffr uses BLE (Bluetooth Low Energy) to communicate with the app. FuffrBox automatically scans for Fuffr devices and connects to the one closest to the mobile running the app. The RSSI (signal strength) is used to determine which Fuffr devices is closest, if there are multiple devices within scanning range.

The connection process takes a couple of seconds.

When a connection is made, the function **fuffr.on.connected** is called.

On disconnect, the function **fuffr.on.disconnected** is called.

When connected, you can enable the Fuffr by specifying which sides are to be active and the number of touches per side. The following code snippet shows how to enables the left and right side, with 1 touch point per side:

	fuffr.on.connected = function()
	{
		fuffr.enableSides(
			fuffr.FFRSideRight | fuffr.FFRSideLeft,
			1)
	}

Enabling multiple sides is done by bit-or:ing side constants. Available values are:

	fuffr.FFRSideTop
	fuffr.FFRSideBottom
	fuffr.FFRSideLeft
	fuffr.FFRSideRight

To put Fuffr into power saving mode you can disable all sides with:

	fuffr.enableSides(
		0,
		0)

### Receiving touch events

The following functions are called when touch events occur:

* fuffr.on.touchesBegan
* fuffr.on.touchesMoved
* fuffr.on.touchesEnded

The touch functions take one parameter, an array of touch objects.

Each touch object has the following fields:

* {number} side - side of the touch, one of the FFRSide* values
* {number} id - uniquely identifies the touch
* {number} x - raw x coordinate
* {number} y - raw y coordinate
* {number} prevx - previous raw x coordinate
* {number} prevy - previous raw y coordinate
* {number} normx - normalized x coordinate (a real number between 0 and 1)
* {number} normy - normalized y coordinate (a real number between 0 and 1)

Here is an example:

	fuffr.on.touchesBegan = function(touches)
	{
		var touch = touches[0]
		var x = touch.x
		var y = touch.y
		// Display something at x,y
	}

## The Gesture API

The FuffrLib JavaScript library has a gesture API that facilitates using common gestures in your application.

### Gesture types

The following gesture recognizers are available in the library:

* fuffr.FFRGesturePan
* fuffr.FFRGesturePinch
* fuffr.FFRGestureRotate
* fuffr.FFRGestureTap
* fuffr.FFRGestureDoubleTap
* fuffr.FFRGestureLongPress
* fuffr.FFRGestureSwipeLeft
* fuffr.FFRGestureSwipeRight
* fuffr.FFRGestureSwipeUp
* fuffr.FFRGestureSwipeDown

Below follows example for how to use these gestures.

### Adding and removing gestures

Multiple gestures can be enabled. Gestures are added by fuffr.addGesture:

    fuffr.addGesture(gestureType, side, callbackFunction)

Some gesture types accept a dictionary object of gesture parameters:

    fuffr.addGesture(gestureType, side, parameters, callbackFunction)

The fuffr.addGesture function returns an id you can use to remove a gesture by calling fuffr.removeGesture:

    var gestureId = fuffr.addGesture(...)
    ...
    fuffr.removeGesture(gestureId)

Remove all gestures with fuffr.removeAllGestures:

    fuffr.removeAllGestures()


### Example of fuffr.FFRGesturePan

Here is an example of how to setup a pan recognizer (onPan is a function you name and define):

	fuffr.addGesture(
		fuffr.FFRGesturePan,
		fuffr.FFRSideRight,
		onPan)

The onPan function looks like this (you give this function any name):

	function onPan(state, width, height)
	{
		// width and height contains the translation from the
		// original touch point that started the gesture.
	}

Possible values of **state**:

** fuffr.FFRGestureRecognizerStateBegan - gesture started
** fuffr.FFRGestureRecognizerStateChanged - gesture value has been updated
** fuffr.FFRGestureRecognizerStateEnded - gesture has ended

Note that the width and height of the translation is relative to the original touch point that started the gesture (they are not delta values).

### Example of fuffr.FFRGesturePinch

Here is how to setup a pinch recognizer:

	fuffr.addGesture(
		fuffr.FFRGesturePinch,
		fuffr.FFRSideRight,
		onPinch)

The function that is called when a gesture occurs:

    function onPinch(state, scale)
	{
		// scale contains a decimal value representing the
		// distance from the original touch points.
    }

The scale value is based on the distance between the original touch points that started the gesture (it is not a delta value).

Possible values of **state**:

** fuffr.FFRGestureRecognizerStateBegan - gesture started
** fuffr.FFRGestureRecognizerStateChanged - gesture value has been updated
** fuffr.FFRGestureRecognizerStateEnded - gesture has ended

### Example of fuffr.FFRGestureRotate

Here is an example of how to setup a rotation recognizer:

	fuffr.addGesture(
		fuffr.FFRGestureRotate,
		fuffr.FFRSideRight,
		onPinch)

Callback function:

    function onPinch(state, rotation)
	{
		// rotation contains a decimal value representing
		// the rotation in radians.
    }

The rotation value is based on the angle between the original touch points that started the gesture (it is not a delta value). The angle is given in radians.

Possible values of **gesture.state**:

** fuffr.FFRGestureRecognizerStateBegan - gesture started
** fuffr.FFRGestureRecognizerStateChanged - gesture value has been updated
** fuffr.FFRGestureRecognizerStateEnded - gesture has ended

### Example of fuffr.FFRGestureTap

Example of how to setup a tap recognizer:

	fuffr.addGesture(
		fuffr.FFRGestureTap,
		fuffr.FFRSideLeft,
		{ maximumDuration: 1.0 },
		onTap)

Possible parameter values are:

* maximumDuration - max time in seconds between finger down/up for gesture to trigger
* maximumDistance - max distance for finger to move for gesture to trigger

Function called when a tap gesture occurs:

    function onTap(state)
	{
		// Tap occured (state is not used).
    }

### Example of fuffr.FFRGestureDoubleTap

Example of how to setup a double tap recognizer:

	fuffr.addGesture(
		fuffr.FFRGestureDoubleTap,
		fuffr.FFRSideLeft,
		{ maximumDuration: 1.5 },
		onDoubleTap)

Possible parameter values are:

* maximumDuration - max time in seconds between finger down/up/down/up for gesture to trigger
* maximumDistance - max distance for finger to move for gesture to trigger

Example of function called when a double tap gesture occurs:

    function onDoubleTap(state)
	{
		// Double tap occured (state is not used).
    }


### Example of fuffr.FFRGestureLongPress

Example of how to setup a long press recognizer:

	fuffr.addGesture(
		fuffr.FFRGestureLongPress,
		fuffr.FFRSideLeft,
		{ minimumDuration: 1.5 },
		onLongPress)

Possible parameter values are:

* minimumDuration - min time in seconds between finger down for gesture to trigger
* maximumDistance - max distance for finger to move for gesture to trigger

Function called when a long press occurs:

    function onLongPress(state)
	{
		// Long press occured (state is not used).
    }

### Swipe gestures

Available Swipe gesture types are:

* fuffr.FFRGestureSwipeLeft
* fuffr.FFRGestureSwipeRight
* fuffr.FFRGestureSwipeUp
* fuffr.FFRGestureSwipeDown

This is an example of how to setup a swipe up gesture recognizer:

	fuffr.addGesture(
		fuffr.FFRGestureSwipeUp,
		fuffr.FFRSideRight,
		{ minimumDistance: 200.0,
		  maximumDuration: 1.0 },
		onSwipeUp)

    FFRSwipeGestureRecognizer* swipeLeft = [FFRSwipeGestureRecognizer new];
    swipeLeft.side = FFRSideLeft | FFRSideRight;
    swipeLeft.direction = FFRSwipeGestureRecognizerDirectionLeft;
    swipeLeft.minimumDistance = 200.0;
    swipeLeft.maximumDuration = 1.0; // 1 second.
    [swipeLeft addTarget: self action: @selector(onSwipeLeft:)];
    [manager addGestureRecognizer: swipeLeft];

Possible parameter values for Swipe gestures are:

* maximumDuration - max time in seconds for touch down and movement for gesture to trigger
* minimumDistance - min distance for finger to move for gesture to trigger

Example of function called when swipe occurs:

    function onSwipeUp(state)
	{
		// Swipe occured (state is not used).
    }

## Provide feedback

Let us know what you think! We would love to hear about the Fuffr apps you create. Let us know about your work, what you think Fuffr, the API, and please report any bugs you encounter.

Contact: hello@fuffr.com
