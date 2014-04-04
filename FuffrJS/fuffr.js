var fuffr = {}

fuffr.FFRSideTop = 1
fuffr.FFRSideBottom = 2
fuffr.FFRSideLeft = 4
fuffr.FFRSideRight = 8

fuffr.basicLeftRightTouchHandler = function(touches)
{
	var foundLeftTouch = false;
	var foundRightTouch = false;

	for (var i = 0; i < touches.length; ++i)
	{
		var touch = touches[i]
		if (touch.side == fuffr.FFRSideLeft && !foundLeftTouch)
		{
			 foundLeftTouch = true;
			 OnLeftTouch(
			 	touch.id,
			 	touch.x,
			 	touch.y,
			 	touch.prevx,
			 	touch.prevy,
			 	touch.normx,
			 	touch.normy)
		}
		if (touch.side == fuffr.FFRSideRight && !foundRightTouch)
		{
			 foundRightTouch = true;
			 OnRightTouch(
			 	touch.id,
			 	touch.x,
			 	touch.y,
			 	touch.prevx,
			 	touch.prevy,
			 	touch.normx,
			 	touch.normy)
		}
	}
}

fuffr.onTouchesBegan = fuffr.basicLeftRightTouchHandler
fuffr.onTouchesMoved = fuffr.basicLeftRightTouchHandler
fuffr.onTouchesEnded = fuffr.basicLeftRightTouchHandler
