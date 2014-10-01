//
//  ViewController.m
//  FuffrBird
//
//  Created by Emil Braide on 22/05/14.
//
//  App based on Flappy Bird from Matt Heaney Apps channel on youtube.
//  Link: https://www.youtube.com/channel/UCQkn7EImMp5sHtFbALgYrsA
//
//  Background music composer: Ozzed
//  Link: http://ozzed.net/


#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	highScoreNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"highScoreSaved"];
	highScore.text = [NSString stringWithFormat:@"HighScore: %li", (long)highScoreNumber];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self fuffrSetup];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(receivedNotification:)
		name:@"FuffrDisconnected"
		object:nil];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	fuffrLabel.text = [NSString stringWithFormat:@"Searching for Fuffr Device..."];
    backGroundImageView.image = [UIImage imageNamed:@"fuffrBackgroundRed.png"];
}

- (void)fuffrSetup
{
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	[manager
	 onFuffrConnected:
	 ^{
		 [manager useSensorService:
		  ^{
			  fuffrLabel.text = [NSString stringWithFormat:@"Fuffr Connected!"];
              backGroundImageView.image = [UIImage imageNamed:@"fuffrBackground.png"];
				// Set active sides.
				[[FFRTouchManager sharedManager]
					enableSides: FFRSideLeft | FFRSideRight | FFRSideBottom
					touchesPerSide: @1
			   ];
		  }];
	 }
	 onFuffrDisconnected:
	 ^{
		 fuffrLabel.text = [NSString stringWithFormat:@"Fuffr Disconnected! Attempting To Reconnect"];
         backGroundImageView.image = [UIImage imageNamed:@"fuffrBackgroundRed.png"];
	 }];

	// Register gesture handler.
	FFRTapGestureRecognizer* tap = [FFRTapGestureRecognizer new];
	tap.side = FFRSideLeft;
	tap.maximumDistance = 50.0;
	tap.maximumDuration = 0.5; // 0.5 seconds.
	[tap addTarget: self action: @selector(onTap:)];
	[manager addGestureRecognizer: tap];
}

-(void) onTap: (FFRTapGestureRecognizer*)gesture
{
	FFRTouchManager* manager = [FFRTouchManager sharedManager];
	[manager removeAllGestureRecognizers];
	[self performSegueWithIdentifier:@"StartGameSegue" sender:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)receivedNotification:(id)sender
{
	fuffrLabel.text = [NSString stringWithFormat:@"Fuffr Disconnected during gameplay. Reconnect and try again"];
    backGroundImageView.image = [UIImage imageNamed:@"fuffrBackgroundRed.png"];
}

@end
