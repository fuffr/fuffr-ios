//
//  Game.m
//  FuffrBird
//
//  Created by Fuffr2 on 22/05/14.
//  Copyright (c) 2014 BraidesAppHouse. All rights reserved.
//
//  App based on Flappy Bird from Matt Heaney Apps channel on youtube.
//  Link: https://www.youtube.com/channel/UCQkn7EImMp5sHtFbALgYrsA
//

#import "Game.h"

@interface Game ()

@end

@implementation Game

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	// Setup the visable variables and the gap between the tunnels.
	gameStarted = NO;
	gameOver = NO;
	tunnelTop.hidden = YES;
	tunnelBottom.hidden = YES;
	scoreNumber = 0;
	birdFlight = 0;
	tunnelGap = 220;
	highScoreNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScoreSaved"];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self fuffrSetup];
}

- (void)fuffrSetup
{
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];
	
	// Send a message to menuview that fuffr disconnected and
	// dismiss the viewcontroller.
	[manager onFuffrDisconnected:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FuffrDisconnected" object:nil];
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
	
	// setup the gestures for the game
	FFRSwipeGestureRecognizer* swipeUp = [FFRSwipeGestureRecognizer new];
	swipeUp.side = FFRSideRight;
	swipeUp.direction = FFRSwipeGestureRecognizerDirectionUp;
	swipeUp.minimumDistance = 50.0;
	swipeUp.maximumDuration = 3.0;
	[swipeUp addTarget: self action: @selector(onSwipeUp:)];
	[manager addGestureRecognizer: swipeUp];
	
	FFRTapGestureRecognizer* tap = [FFRTapGestureRecognizer new];
	tap.side = FFRSideLeft;
	tap.maximumDistance = 50.0;
	tap.maximumDuration = 0.5;
	[tap addTarget: self action: @selector(onTap:)];
	[manager addGestureRecognizer: tap];
	
	FFRTapGestureRecognizer *tapBottom = [FFRTapGestureRecognizer new];
	tapBottom.side = FFRSideBottom;
	tapBottom.maximumDistance = 50.0;
	tapBottom.maximumDuration = 0.5;
	[tapBottom addTarget:self action:@selector(onTapBottom:)];
	[manager addGestureRecognizer:tapBottom];
}

- (IBAction)startGame:(id)sender
{
	gameStarted = YES;
	tunnelTop.hidden = NO;
	tunnelBottom.hidden = NO;
	startLabel.hidden = YES;
	bomb.hidden = NO;
	birdMovement = [NSTimer
		scheduledTimerWithTimeInterval:0.05
		target:self
		selector:@selector(birdMoving)
		userInfo:nil
		repeats:YES];
	[self placeTunnels];
	tunnelMovement = [NSTimer
		scheduledTimerWithTimeInterval:0.01
		target:self
		selector:@selector(tunnelMoving)
		userInfo:nil
		repeats:YES];
}

- (void)gameOver
{
	// update the highscore
	if (scoreNumber > highScoreNumber)
	{
		[[NSUserDefaults standardUserDefaults] setInteger:scoreNumber forKey:@"highScoreSaved"];
	}
	
	// Update the view and stop the NSTimers.
	[tunnelMovement invalidate];
	[birdMovement invalidate];
	tunnelTop.hidden = YES;
	tunnelBottom.hidden = YES;
	bird.hidden = YES;
	gameOver = YES;
	startLabel.text = [NSString stringWithFormat:@"Tap on the left side to exit the game"];
	startLabel.hidden = NO;
}

- (void)score
{
	scoreNumber++;
	scoreLabel.text = [NSString stringWithFormat:@"%i", scoreNumber];
}

- (void)placeTunnels
{
	randomTopTunnelPosition = arc4random() % (int)(self.view.bounds.size.height-tunnelGap);
	randomBottomTunnelPosition = randomTopTunnelPosition + tunnelGap;
	[tunnelTop setFrame:CGRectMake(
		self.view.bounds.size.width,
		(randomTopTunnelPosition - tunnelTop.frame.size.height),
		tunnelTop.frame.size.width,
		tunnelTop.frame.size.height)];
	[tunnelBottom setFrame:CGRectMake(
		self.view.bounds.size.width,
		randomBottomTunnelPosition,
		tunnelBottom.frame.size.width,
		tunnelBottom.frame.size.height)];
}

-(void)tunnelMoving
{
	tunnelTop.center = CGPointMake(tunnelTop.center.x - 1, tunnelTop.center.y);
	tunnelBottom.center = CGPointMake(tunnelBottom.center.x - 1, tunnelBottom.center.y);
	
	// look if the tunnels have passed the screen
	if(tunnelTop.center.x < -(tunnelTop.bounds.size.width))
	{
		[self placeTunnels];
	}
	
	// check if the bird has passed the tunnels and award a score point
	if ((int)tunnelTop.center.x == (int)bird.center.x)
	{
		[self score];
	}
	
	// check for collisions. End the game if the bird has hit anything
	if (CGRectIntersectsRect(bird.frame, tunnelTop.frame) ||
		CGRectIntersectsRect(bird.frame, tunnelBottom.frame) ||
		CGRectIntersectsRect(bird.frame, top.frame) ||
		CGRectIntersectsRect(bird.frame, bottom.frame))
	{
		[self gameOver];
	}
}

- (void)birdMoving
{
	// Set the new point for the moving bird.
	bird.center = CGPointMake(bird.center.x, bird.center.y - birdFlight);
	
	birdFlight -= 5;
	
	if (birdFlight < -15)
	{
		birdFlight = -15;
	}
}

-(void) onTap: (FFRTapGestureRecognizer*)gesture
{
	// Tap on the left side, dismiss the viewcontroller if the game
	// is over or start the game if it hasn't started.
	if(gameOver)
	{
		FFRTouchManager* manager = [FFRTouchManager sharedManager];
		[manager removeAllGestureRecognizers];
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	else if (!gameStarted)
	{
		[self startGame:self];
	}
}

- (void)onTapBottom: (FFRTapGestureRecognizer *)gesture
{
	if (gameStarted)
	{
		if (!bomb.hidden)
		{
			[self placeTunnels];
			bomb.hidden = YES;
		}
	}
}

- (void)onSwipeUp:(FFRSwipeGestureRecognizer *)gesture
{
	if (gameStarted)
	{
		// Add the upward velocity and animate the bird.
		birdFlight = 26;
		CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
		animation.fromValue = @(M_PI);
		animation.toValue = @(2*M_PI);
		animation.duration = 0.5f; // this might be too fast
		[bird.layer addAnimation:animation forKey:@"rotation"];
	}
}

@end
