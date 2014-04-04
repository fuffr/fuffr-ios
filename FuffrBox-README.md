# FuffrBox info

Project FuffrBox is an simple browser that sends Fuffr touch
events to the currently loaded page.

Basic examples available at: kindborg.com/fuffr

First activate Fuffr by pressing the small top-left switch.
(if needed, first reset by pressing bottom-right switch)

Then start the FuffrBox app, it should connect to Fuffr
automatically. If it does not work, try to reset the case
and restart the app (app must be closed/terminated before
launching it again).

JavaScript functions that are called:

fuffr.onTouchesBegan(touchesArray)
fuffr.onTouchesMoved(touchesArray)
fuffr.onTouchesEnded(touchesArray)

touchesArray has the format:

[touch1,touch2,...]

A touch object has the format:

{
    id: a numberical touch id
    side: id or the side of the touch (see fuffr.js for values)
    x: touch x pos mapped to the screen
    y: touch y pos mapped to the screen
    prevx: previous touch x pos
    prevy: previous touch y pos
    normx: normalized touch x pos (value between 0..1)
    normy: normalized touch y pos (value between 0..1)
}

Experimental examples in folder FuffrJS:

dancing-squares.html
vibrant-field.html
pong.html

Useful file:

fuffr.js

To track a touch in a consistent way, the id property
should be used. The code in fuffr.js currently just
picks the first touch in the list of touches for the
given side. This can result in jumpy coordinates. Use
the id for tracking touches.

The WebGL examples are just to test that WebGL works,
they are not processing touch events.
