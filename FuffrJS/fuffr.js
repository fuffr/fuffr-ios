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

// Event functions.
// Assign your own functions to these functions.

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
    fuffr.callNative('domLoaded@')
})
