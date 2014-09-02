//
//  ViewController.h
//  FuffrBird
//
//  Created by Emil Braide on 22/05/14.
//
//  App based on Flappy Bird from Matt Heaney Apps channel on youtube.
//  Link: https://www.youtube.com/channel/UCQkn7EImMp5sHtFbALgYrsA
//
//  Background music composer: Ozzed
//  Link: http://ozzed.net/


#import <UIKit/UIKit.h>
#import <FuffrLib/FFRTouchManager.h>
#import "Game.h"

NSInteger highScoreNumber;
NSString *fuffrStatusString;

@interface ViewController : UIViewController
{
	IBOutlet UILabel *highScore;
	IBOutlet UILabel *fuffrLabel;
    __weak IBOutlet UIImageView *backGroundImageView;
}

@end
