
var lang = {}
var game = {}
var gfx = {}

/* Called when document is loaded and ready. */
$(function() {
	//setTimeout(fuffrHandler.checkConnection, fuffrHandler.connTimeoutMs)

	$('#restart-button').bind('click', function(event) {
		game.restart()
	})

	game.initialize()
	gfx.initialize()

	resetPlayfield()

	game.start()
})

game.mainLoopBaseIntervalMs = 21
game.levels = 10
game.speedIncreasePerLevel = 1
game.scorePointsPerLevel = 5
game.secondsPerLevel = 30

lang.missing_init = 'Couldn\'t start the game.'
lang.fuffr_not_connected = 'Fuffr wasn\'t connected. Do you want to use the simulator?'
lang.game_finished_text = 'Player %1 wins the game!'
lang.game_finished_draw_text = 'We have a draw!'

game.initialize = function()
{
	this.playfieldWidth = $('#playfield').width()
	this.playfieldHeight = $('#playfield').height()

	this.level = 1
	this.levelNumberElm = document.getElementById('level')
	this.speed = 1

	this.player1 = {
		score: 0,
		scoreElement : document.getElementById('score-left'),
	}
	this.player2 = {
		score: 0,
		scoreElement : document.getElementById('score-right'),
	}

	this.levelNumberElm.textContent = this.level
	this.player1.scoreElement.textContent = 0
	this.player2.scoreElement.textContent = 0

	$('#game-finished-overlay').hide()
	$('#playfield').removeClass('dimmed')
}

game.start = function()
{
	if (ball == void(0) || gfx.paddleLeft == void(0) || gfx.paddleRight == void(0))
	{
		alert(lang.missing_init)
	}

	this.startLevel()
}

game.startLevel = function()
{
	if (this.mainLoop)
		window.clearInterval(this.mainLoop)

	this.levelStartTime = (new Date().getTime())

	if (!this.startTime)
		this.startTime = this.levelStartTime

	var that = this
	this.mainLoop = window.setInterval(function()
	{
		that.checkTimePerLevel()
		gfx.ball.move()
		gfx.paddleLeft.measureSpeed()
		gfx.paddleRight.measureSpeed()
		gfx.ball.checkLeftPaddleCollision()
		gfx.ball.checkRightPaddleCollision()
		gfx.ball.checkWallCollision()
	},
	game.mainLoopBaseIntervalMs - game.speed)
}

game.end = function()
{
	window.clearInterval(this.mainLoop)

	var winning_player = null
	if (game.player1.score > game.player2.score) winning_player = 1
	if (game.player2.score > game.player1.score) winning_player = 2

	$('#playfield').addClass('dimmed')
	if (winning_player != null)
	{
		$('#game-finished-overlay-header').text(lang.game_finished_text.replace('%1', winning_player))
	}
	else
	{
		$('#game-finished-overlay-header').text(lang.game_finished_draw_text)
	}
	$('#game-finished-overlay').show()
}

game.restart = function()
{
	game.initialize()
	game.start()
}

game.increaseScore = function(player) {
	player.score += 1

	player.scoreElement.textContent = player.score

	if ((game.player1.score + game.player2.score) % game.scorePointsPerLevel == 0)
	{
		game.nextLevel()
	}

	gfx.ball.setCenterX(this.playfieldWidth / 2)
	gfx.ball.setCenterY(this.playfieldHeight / 2)
}

game.nextLevel = function()
{
	this.level += 1

	if (this.level > this.levels)
	{
		this.end()
	}
	else
	{
		game.levelNumberElm.textContent = this.level
		game.speed += game.speedIncreasePerLevel
		this.startLevel()
	}
}

game.getPlaytimeSeconds = function()
{
	var time = (new Date().getTime())
	return Math.round((time - this.startTime) / 1000)
}

game.getLevelPlaytimeSeconds = function()
{
	var time = (new Date().getTime())
	return Math.round((time - this.levelStartTime) / 1000)
}

game.checkTimePerLevel = function()
{
	if (this.getLevelPlaytimeSeconds() >= game.secondsPerLevel)
		this.nextLevel()
}

gfx.initialize = function()
{
	if (game.playfieldWidth == void(0) || game.playfieldHeight == void(0))
		gfx.failedToInitialize()

	gfx.paddleLeft.setDOMElement(document.getElementById('paddle-left'))
	gfx.paddleLeft.setLeft(0)
	gfx.paddleLeft.setCenterY(game.playfieldHeight / 2)
	gfx.paddleLeft.lastX = null
	gfx.paddleLeft.lastY = null
	gfx.paddleLeft.speedX = 0
	gfx.paddleLeft.speedY = 0
	gfx.paddleLeft.speedXMax = 0
	gfx.paddleLeft.speedYMax = 50

	gfx.paddleRight.setDOMElement(document.getElementById('paddle-right'))
	gfx.paddleRight.setRight(game.playfieldWidth)
	gfx.paddleRight.setCenterY(game.playfieldHeight / 2)
	gfx.paddleRight.lastX = null
	gfx.paddleRight.lastY = null
	gfx.paddleRight.speedX = 0
	gfx.paddleRight.speedY = 0
	gfx.paddleRight.speedXMax = 0
	gfx.paddleRight.speedYMax = 50

	gfx.ball.setDOMElement(document.getElementById('ball'))
	gfx.ball.setCenterX(game.playfieldWidth / 2)
	gfx.ball.setCenterY(game.playfieldHeight / 2)
	gfx.ball.setDeltaX(4)
	gfx.ball.setDeltaY(4)
	gfx.ball.maxDeltaY = 5
}

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
		sprite.width = sprite.domElement.offsetWidth
		sprite.height = sprite.domElement.offsetHeight
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

gfx.paddleLeft = makeSprite()
gfx.paddleRight = makeSprite()
gfx.ball = makeSprite()

gfx.ball.checkWallCollision = function()
{
	var nextX = gfx.ball.getCenterX() + gfx.ball.dx
	var nextY = gfx.ball.getCenterY() + gfx.ball.dy

	// Left wall.
	if (nextX < 0 && gfx.ball.dx < 0)
	{
		gfx.ball.dx = - gfx.ball.dx
		game.increaseScore(game.player2)
	}
	// Right wall.
	else if (nextX > game.playfieldWidth && gfx.ball.dx > 0)
	{
		gfx.ball.dx = - gfx.ball.dx
		game.increaseScore(game.player1)
	}
	// Top wall.
	else if (nextY < 0 && gfx.ball.dy < 0)
	{
		gfx.ball.dy = - gfx.ball.dy
	}
	// Bottom wall.
	else if (nextY > game.playfieldHeight && gfx.ball.dy > 0)
	{
		gfx.ball.dy = - gfx.ball.dy
	}
}

gfx.ball.checkLeftPaddleCollision = function()
{
	var nextX = gfx.ball.getCenterX() + gfx.ball.dx
	var nextY = gfx.ball.getCenterY() + gfx.ball.dy

	var paddle = gfx.paddleLeft

	// Bounce if ball is within paddle bounds.
	if (nextX < paddle.getRight() &&
		nextY > paddle.getTop() &&
		nextY < paddle.getBottom() &&
		gfx.ball.dx < 0)
	{
		console.log('collide left paddle')
		gfx.ball.dx = - gfx.ball.dx

		var paddleSpeed = (paddle.speedY / paddle.speedYMax),
			collPos = ((nextY - paddle.getCenterY()) / paddle.domElement.offsetHeight),
			speedTerm = paddleSpeed * 5,
			posTerm = paddleSpeed * 0.5 * collPos,
			ballDeltaYChange = speedTerm + posTerm

		if (gfx.ball.dy + ballDeltaYChange > gfx.ball.maxDeltaY)
			gfx.ball.dy = gfx.ball.maxDeltaY
		else
			gfx.ball.dy += ballDeltaYChange

		//console.log('speed term=' + speedTerm + ', pos term=' + posTerm)
	}
}

gfx.ball.checkRightPaddleCollision = function()
{
	var nextX = gfx.ball.getCenterX() + gfx.ball.dx
	var nextY = gfx.ball.getCenterY() + gfx.ball.dy
	// console.log(nextY + '(' + gfx.ball.dy + ')')

	var paddle = gfx.paddleRight

	// Bounce if ball is within paddle bounds.
	if (nextX > paddle.getLeft() &&
		nextY > paddle.getTop() &&
		nextY < paddle.getBottom() &&
		gfx.ball.dx > 0)
	{
		console.log('collide right paddle')
		gfx.ball.dx = - gfx.ball.dx

		var paddleSpeed = (paddle.speedY / paddle.speedYMax),
			collPos = ((nextY - paddle.getCenterY()) / paddle.domElement.offsetHeight),
			speedTerm = paddleSpeed * 5,
			posTerm = paddleSpeed * 0.5 * collPos,
			ballDeltaYChange = speedTerm + posTerm

		if (gfx.ball.dy + ballDeltaYChange > gfx.ball.maxDeltaY)
			gfx.ball.dy = gfx.ball.maxDeltaY
		else
			gfx.ball.dy += ballDeltaYChange

		//console.log('speed term=' + speedTerm + ', pos term=' + posTerm)
	}
}

gfx.paddleLeft.measureSpeed =
gfx.paddleRight.measureSpeed = function()
{
	this.dt += game.mainLoopBaseIntervalMs / 1000
	if (this.dt >= 0.1)
	{
		if (this.lastY)
			this.speedY = (this.y - this.lastY) / this.dt
		this.lastY = this.y
		this.dt = 0
	}
	if (this.speedY > this.speedYMax)
		this.speedYMax = this.speedY
}

gfx.failedToInitialize = function()
{
	alert(lang.missing_init)
	return true
}

var resetPlayfield = function()
{
	game.playfieldWidth = $('#playfield').width()
	game.playfieldHeight = $('#playfield').height()
	gfx.paddleLeft.setLeft(0)
	gfx.paddleRight.setRight(game.playfieldWidth)
}

function OnRightTouch(touchId, touchX, touchY, previousX, previousY, normalizedX, normalizedY)
{
	var y = (normalizedY * game.playfieldHeight)
	gfx.paddleRight.setCenterY(y)
}

function OnLeftTouch(touchId, touchX, touchY, previousX, previousY, normalizedX, normalizedY)
{
	var y = (normalizedY * game.playfieldHeight)
	gfx.paddleLeft.setCenterY(y)
}

var fuffrHandler = {}

fuffrHandler.wasConnected = false
fuffrHandler.connTimeoutMs = 3000

fuffrHandler.checkConnection = function()
{
	if (false === fuffrHandler.wasConnected) {
		if (confirm(lang.fuffr_not_connected))
			simulator.enable()
	}
}

fuffr.on.connected = function()
{
	//console.log('Fuffr Connected!')
	fuffr.enableSides(
		fuffr.FFRSideRight | fuffr.FFRSideLeft,
		1)
	fuffrHandler.wasConnected = true
}

function touchHandler(touches)
{
	var foundLeftTouch = false
	var foundRightTouch = false

	for (var i = 0; i < touches.length; ++i)
	{
		var touch = touches[i]
		if (touch.side == fuffr.FFRSideLeft && !foundLeftTouch)
		{
			 foundLeftTouch = true
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
			 foundRightTouch = true
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

var simulator = {}

simulator.enable = function()
{
	$('#playfield').addClass('with-simulator')
	$('#left-touch-area, #right-touch-area').show()
	resetPlayfield()

	var element = document.getElementById('left-touch-area')
	Hammer(element).on("touch", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesBegan)
	})
	Hammer(element).on("gesture", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesMoved)
	})
	Hammer(element).on("release", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesEnded)
	})

	var element = document.getElementById('right-touch-area')
	Hammer(element).on("touch", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesBegan)
	})
	Hammer(element).on("gesture", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesMoved)
	})
	Hammer(element).on("release", function(event) {
		simulator.handleHammerTouchEvent(event, fuffr.on.touchesEnded)
	})
}

simulator.disable = function()
{
	$('#left-touch-area, #right-touch-area').hide()
	$('#playfield').removeClass('with-simulator')
	resetPlayfield()
}

simulator.handleHammerTouchEvent = function(event, handler)
{
	var touches = []

	for (var t in event.gesture.touches) {
		var touch = event.gesture.touches[t]
		if ('object' != typeof touch) continue;

		var side = null
		if (touch.target.id == 'left-touch-area')
			side = fuffr.FFRSideLeft
		if (touch.target.id == 'right-touch-area')
			side = fuffr.FFRSideRight

		var touchX = touch.x || touch.clientX
		var touchY = touch.y || touch.clientY

		touches.push({
			id	  : touch.identifier,
			x	  : touchX,
			y	  : touchY,
			prevx : touchX,
			prevy : touchY,
			normx : touchX / touch.target.clientWidth,
			normy : touchY / touch.target.clientHeight,
			side  : side
		})
	}

	handler(touches)
}
