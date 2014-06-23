//
//  Game.h
//  FuffrBird
//
//  Created by Fuffr2 on 22/05/14.
//  Copyright (c) 2014 BraidesAppHouse. All rights reserved.
//
//  App based on Flappy Bird from Matt Heaney Apps channel on youtube.
//  Link: https://www.youtube.com/channel/UCQkn7EImMp5sHtFbALgYrsA
//

#import <UIKit/UIKit.h>
#import <FuffrLib/FFRTouchManager.h>
#import "ViewController.h"

int birdFlight;
int randomTopTunnelPosition;
int randomBottomTunnelPosition;
int scoreNumber;
int tunnelGap;
BOOL gameOver;
BOOL gameStarted;
NSInteger highScoreNumber;

@interface Game : UIViewController
{
	IBOutlet UIImageView *bird;
	IBOutlet UILabel *startLabel;
	IBOutlet UIImageView *tunnelTop;
	IBOutlet UIImageView *tunnelBottom;
	IBOutlet UIImageView *top;
	IBOutlet UIImageView *bottom;
	IBOutlet UILabel *scoreLabel;
	IBOutlet UIImageView *bomb;
	NSTimer *birdMovement;
	NSTimer *tunnelMovement;
}

- (void)startGame;
- (void)birdMoving;
- (void)tunnelMoving;
- (void)placeTunnels;
- (void)score;
- (void)gameOver;

@end
