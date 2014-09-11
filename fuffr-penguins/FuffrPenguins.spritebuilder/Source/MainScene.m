//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"

@implementation MainScene
{
    CCSprite *_fuffrLogo;
}

- (void)didLoadFromCCB
{
    // access audio object
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    
    // play sound effect
    [audio stopEverything];
    _fuffrLogo.color = [CCColor grayColor];
    [self fuffrSetup];
}

- (void)play {
    CCScene *gameplayScene = [CCBReader loadAsScene:@"Gameplay"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}

- (void) fuffrSetup
{
    // Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];
    
    
	// Set active sides.
    [[FFRTouchManager sharedManager] enableSides: 0  touchesPerSide: @0];
	// Register methods for right side touches. The touchEnded
	// method is not used in this example.
    
    [manager
     onFuffrConnected:
     ^{
         [manager useSensorService:
          ^{
              [[FFRTouchManager sharedManager] enableSides: 0 touchesPerSide:@0];
              CCColor *color = [CCColor colorWithRed:1 green:1 blue:1];
              _fuffrLogo.color = color;
          }];
     }
     onFuffrDisconnected:
     ^{
         _fuffrLogo.color = [CCColor grayColor];
     }];
    
    [manager removeAllTouchObserversAndTouchBlocks];
}

@end
