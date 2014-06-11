//
//  ViewController.h
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
#import "Game.h"

NSInteger highScoreNumber;
NSString *fuffrStatusString;

@interface ViewController : UIViewController
{
	IBOutlet UILabel *highScore;
	IBOutlet UILabel *fuffrLabel;
}

@end
