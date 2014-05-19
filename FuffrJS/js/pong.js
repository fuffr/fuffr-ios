function touchHandler(touches)
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

fuffr.on.touchesBegan = touchHandler
fuffr.on.touchesMoved = touchHandler
fuffr.on.touchesEnded = touchHandler

var lang = {};
lang.missing_init = 'Couldn\'t start the game.';
lang.fuffr_not_connected = 'Fuffr wasn\'t connected. Do you want to use the simulator?';

var game = {};

game.mainLoopBaseIntervalMs = 21;
game.levels = 10;
game.speedIncreasePerLevel = 2;
game.scorePointsPerLevel = 5;
game.secondsPerLevel = 30;

game.initialize = function()
{
	this.playfieldWidth = $('#playfield').width();
	this.playfieldHeight = $('#playfield').height();

	this.level = 1;
	this.levelNumberElm = document.getElementById('level');
	this.speed = 1;

	this.player1 = {
		score: 0,
		scoreElement : document.getElementById('score-left'),
	};
	this.player2 = {
		score: 0,
		scoreElement : document.getElementById('score-right'),
	};
};

var fuffrHandler = {};

fuffrHandler.wasConnected = false;
fuffrHandler.connTimeoutMs = 3000;

fuffrHandler.checkConnection = function()
{
	if (false === fuffrHandler.wasConnected) {
		if (confirm(lang.fuffr_not_connected))
			simulator.enable()
	}
};

fuffr.on.connected = function()
{
	hyper.log('Fuffr Connected!')
	fuffr.enableSides(
		fuffr.FFRSideRight | fuffr.FFRSideLeft,
		1)
	fuffrHandler.wasConnected = true;
}

var simulator = {};

simulator.enable = function()
{
	$('#playfield').addClass('with-simulator');
	$('#left-touch-area, #right-touch-area').show();
	resetPlayfield();

	var element = document.getElementById('left-touch-area');
	Hammer(element).on("touch", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesBegan);
	});
	Hammer(element).on("gesture", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesMoved);
	});
	Hammer(element).on("release", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesEnded);
	});

	var element = document.getElementById('right-touch-area');
	Hammer(element).on("touch", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesBegan);
	});
	Hammer(element).on("gesture", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesMoved);
	});
	Hammer(element).on("release", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesEnded);
	});
};

simulator.disable = function()
{
	$('#left-touch-area, #right-touch-area').hide();
	$('#playfield').removeClass('with-simulator');
	resetPlayfield();
};

simulator.handleHammerTouchEvent = function(event, handler)
{
	var touches = [];

	for (var t in event.gesture.touches) {
		var touch = event.gesture.touches[t];
		if ('object' != typeof touch) continue;

		var side = null;
		if (touch.target.id == 'left-touch-area')
			side = fuffr.FFRSideLeft;
		if (touch.target.id == 'right-touch-area')
			side = fuffr.FFRSideRight;

		var touchX = touch.x || touch.clientX;
		var touchY = touch.y || touch.clientY;

		touches.push({
			id	  : touch.identifier,
			x	  : touchX,
			y	  : touchY,
			prevx : touchX,
			prevy : touchY,
			normx : touchX / touch.target.clientWidth,
			normy : touchY / touch.target.clientHeight,
			side  : side
		});
	}

	handler(touches);
};

game.start = function()
{
	if (ball == void(0) || paddleLeft == void(0) || paddleRight == void(0))
	{
		alert(lang.missing_init);
	}

	this.startLevel();
};

game.startLevel = function()
{
	if (this.mainLoop)
		window.clearInterval(this.mainLoop);

	var that = this;
	this.mainLoop = window.setInterval(function()
	{
		that.checkTimePerLevel();
		ball.move()
		paddleLeft.measureSpeed()
		paddleRight.measureSpeed()
		ball.checkLeftPaddleCollision()
		ball.checkRightPaddleCollision()
		ball.checkWallCollision()
	},
	game.mainLoopBaseIntervalMs - game.speed);

	this.levelStartTime = (new Date().getTime());

	if (!this.startTime)
		this.startTime = this.levelStartTime;
};

game.end = function()
{
	window.clearInterval(this.mainLoop);
};

game.increaseScore = function(player) {
	player.score += 1;

	player.scoreElement.textContent = player.score;

	if ((game.player1.score + game.player2.score) % game.scorePointsPerLevel == 0)
	{
		game.nextLevel();
	}
	
	ball.setCenterX(this.playfieldWidth / 2);
	ball.setCenterY(this.playfieldHeight / 2);
}

game.nextLevel = function()
{
	this.level += 1;

	if (this.level > this.levels)
	{
		this.end();
	}
	else
	{
		game.levelNumberElm.textContent = this.level;
		game.speed += game.speedIncreasePerLevel;
		this.startLevel();
	}
};

game.getPlaytimeSeconds = function()
{
	var time = (new Date().getTime());
	return Math.round((time - game.startTime) / 1000);
};

game.getLevelPlaytimeSeconds = function()
{
	var time = (new Date().getTime());
	return Math.round((time - game.levelStartTime) / 1000);
};

game.checkTimePerLevel = function()
{
	if (this.getLevelPlaytimeSeconds() >= game.secondsPerLevel)
		this.nextLevel()
};

var makeSprite = function()
{
	var sprite = {}

	sprite.x = 0
	sprite.y = 0
	sprite.dx = 0
	sprite.dy = 0
	sprite.dt = 0

	sprite.setDOMElement = function(element)
	{
		sprite.domElement = element
		sprite.width = sprite.domElement.offsetWidth;
		sprite.height = sprite.domElement.offsetHeight;
	}

	sprite.setLeft = function(x)
	{
		sprite.x = x
		sprite.domElement.style.left = x + 'px'
	}

	sprite.setRight = function(x)
	{
		sprite.x = x - sprite.domElement.offsetWidth
		sprite.domElement.style.left = sprite.x + 'px'
	}

	sprite.setTop = function(y)
	{
		sprite.y = y
		sprite.domElement.style.top = y + 'px'
	}

	sprite.setBottom = function(y)
	{
		sprite.y = y - sprite.domElement.offsetHeight
		sprite.domElement.style.bottom = sprite.y.offsetHeight + 'px'
	}

	sprite.setCenterX = function(x)
	{
		sprite.setLeft(x - (sprite.domElement.offsetWidth / 2))
	}

	sprite.setCenterY = function(y)
	{
		sprite.setTop(y - (sprite.domElement.offsetHeight / 2))
	}

	sprite.setDeltaX = function(dx)
	{
		sprite.dx = dx
	}

	sprite.setDeltaY = function(dy)
	{
		sprite.dy = dy
	}

	sprite.getCenterX = function()
	{
		return sprite.x + (sprite.domElement.offsetWidth / 2)
	}

	sprite.getCenterY = function()
	{
		return sprite.y + (sprite.domElement.offsetHeight / 2)
	}

	sprite.getLeft = function()
	{
		return sprite.x
	}

	sprite.getRight = function()
	{
		return sprite.x + sprite.domElement.offsetWidth
	}

	sprite.getTop = function()
	{
		return sprite.y
	}

	sprite.getBottom = function()
	{
		return sprite.y + sprite.domElement.offsetHeight
	}

	sprite.move = function()
	{
		sprite.setLeft(sprite.x + sprite.dx)
		sprite.setTop(sprite.y + sprite.dy)
	}

	return sprite
}

var paddleLeft = makeSprite()
var paddleRight = makeSprite()
var ball = makeSprite()

ball.checkWallCollision = function()
{
	var nextX = ball.getCenterX() + ball.dx
	var nextY = ball.getCenterY() + ball.dy

	// Left wall.
	if (nextX < 0 && ball.dx < 0)
	{
		ball.dx = - ball.dx
		game.increaseScore(game.player1);
	}
	// Right wall.
	else if (nextX > game.playfieldWidth && ball.dx > 0)
	{
		ball.dx = - ball.dx
		game.increaseScore(game.player2);
	}
	// Top wall.
	else if (nextY < 0 && ball.dy < 0)
	{
		ball.dy = - ball.dy
	}
	// Bottom wall.
	else if (nextY > game.playfieldHeight && ball.dy > 0)
	{
		ball.dy = - ball.dy
	}
}

ball.checkLeftPaddleCollision = function()
{
	var nextX = ball.getCenterX() + ball.dx
	var nextY = ball.getCenterY() + ball.dy

	var paddle = paddleLeft

	// Bounce if ball is within paddle bounds.
	if (nextX < paddle.getRight() &&
		nextY > paddle.getTop() &&
		nextY < paddle.getBottom() &&
		ball.dx < 0)
	{
		console.log('collide left paddle')
		ball.dx = - ball.dx

		var paddleSpeed = (paddle.speedY / paddle.speedYMax),
			collPos = ((nextY - paddle.getCenterY()) / paddle.domElement.offsetHeight),
			speedTerm = paddleSpeed * 5,
			posTerm = paddleSpeed * 0.5 * collPos,
			ballDeltaYChange = speedTerm + posTerm;

		if (ball.dy + ballDeltaYChange > ball.maxDeltaY)
			ballDeltaYChange = 2 * ballDeltaYChange - ball.maxDeltaY;

		ball.dy += ballDeltaYChange;

		//console.log('speed term=' + speedTerm + ', pos term=' + posTerm);
	}
}

ball.checkRightPaddleCollision = function()
{
	var nextX = ball.getCenterX() + ball.dx
	var nextY = ball.getCenterY() + ball.dy
	// console.log(nextY + '(' + ball.dy + ')');

	var paddle = paddleRight

	// Bounce if ball is within paddle bounds.
	if (nextX > paddle.getLeft() &&
		nextY > paddle.getTop() &&
		nextY < paddle.getBottom() &&
		ball.dx > 0)
	{
		console.log('collide right paddle')
		ball.dx = - ball.dx

		var paddleSpeed = (paddle.speedY / paddle.speedYMax),
			collPos = ((nextY - paddle.getCenterY()) / paddle.domElement.offsetHeight),
			speedTerm = paddleSpeed * 5,
			posTerm = paddleSpeed * 0.5 * collPos,
			ballDeltaYChange = speedTerm + posTerm;

		if (ball.dy + ballDeltaYChange > ball.maxDeltaY)
			ballDeltaYChange = 2 * ballDeltaYChange - ball.maxDeltaY;

		ball.dy += ballDeltaYChange;

		//console.log('speed term=' + speedTerm + ', pos term=' + posTerm);
	}
}

paddleLeft.measureSpeed =
paddleRight.measureSpeed = function()
{
	this.dt += game.mainLoopBaseIntervalMs / 1000;
	if (this.dt >= 0.1)
	{
		if (this.lastY)
			this.speedY = (this.y - this.lastY) / this.dt;
		this.lastY = this.y;
		this.dt = 0;
	}
	if (this.speedY > this.speedYMax)
		this.speedYMax = this.speedY;
};

var resetPlayfield = function()
{
	game.playfieldWidth = $('#playfield').width()
	game.playfieldHeight = $('#playfield').height()
	paddleLeft.setLeft(0)
	paddleRight.setRight(game.playfieldWidth)
};

function OnRightTouch(touchId, touchX, touchY, previousX, previousY, normalizedX, normalizedY)
{
	var y = (normalizedY * game.playfieldHeight)
	paddleRight.setCenterY(y)
}

function OnLeftTouch(touchId, touchX, touchY, previousX, previousY, normalizedX, normalizedY)
{
	var y = (normalizedY * game.playfieldHeight)
	paddleLeft.setCenterY(y)
}

$(function() {
	setTimeout(fuffrHandler.checkConnection, fuffrHandler.connTimeoutMs);

	game.initialize();

	paddleLeft.setDOMElement(document.getElementById('paddle-left'))
	paddleLeft.setLeft(0)
	paddleLeft.setCenterY(game.playfieldHeight / 2)
	paddleLeft.lastX = null
	paddleLeft.lastY = null
	paddleLeft.speedX = 0
	paddleLeft.speedY = 0
	paddleLeft.speedXMax = 0
	paddleLeft.speedYMax = 50

	paddleRight.setDOMElement(document.getElementById('paddle-right'))
	paddleRight.setRight(game.playfieldWidth)
	paddleRight.setCenterY(game.playfieldHeight / 2)
	paddleRight.lastX = null
	paddleRight.lastY = null
	paddleRight.speedX = 0
	paddleRight.speedY = 0
	paddleRight.speedXMax = 0
	paddleRight.speedYMax = 50

	ball.setDOMElement(document.getElementById('ball'))
	ball.setCenterX(game.playfieldWidth / 2)
	ball.setCenterY(game.playfieldHeight / 2)
	ball.setDeltaX(4)
	ball.setDeltaY(4)
	ball.maxDeltaY = 5;

	resetPlayfield();

	game.start();
});
