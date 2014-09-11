//
//  Gameplay.m
//  FuffrPenguins
//
//  Created by Fuffr2 on 01/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//
//  Background music:
//  "Itty Bitty 8 Bit" Kevin MacLeod (incompetech.com)
//  Licensed under Creative Commons: By Attribution 3.0
//  http://creativecommons.org/licenses/by/3.0/


#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "CCActionInterval.h"
#import "Player.h"
#import "Penguin.h"
#include <CCActionInterval.h>

@implementation Gameplay
{
    CCPhysicsNode *_physicsNode;
    CCNode *_playerOneCannon, *_playerTwoCannon, *_playerOneCannonBase, *_playerTwoCannonBase;
    CCNode *_levelNode;
    CCSprite *_canonShotAnimation;
    CCNode *_contentNode;
    CCSprite *_playerOneIceBlock, *_playerTwoIceBlock;
    CCScene *_levelScene;
    CGFloat maxPowerDistance, maxPowerForce, minPowerForce, minDistance;
    Player *playerOne, *playerTwo;
    CCNodeColor *leftBorder, *rightBorder, *topBorder, *bottomBorder;
    NSTimer *moveIceBlockTimer;
    CCSpriteFrame *iceBlockWithCracks, *iceBlockWithAlotOfCracks;
    CCNode *_midDisplayLabel;
    BOOL gameOver;
}

#pragma mark - Initialization

// is called when CCB file has completed loading
- (void)didLoadFromCCB
{
    // buffer sprites
    iceBlockWithCracks = [CCSpriteFrame frameWithImageNamed:@"GameResources/taperedblockcracked.png"];
    iceBlockWithAlotOfCracks = [CCSpriteFrame frameWithImageNamed:@"GameResources/taperedblockcrackedalot.png"];
    
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    gameOver = NO;
    
    //_playerOneCannon.physicsBody.collisionMask = @[];
    //_playerTwoCannon.physicsBody.collisionMask = @[];
    //_playerOneCannonTop.physicsBody.collisionMask = @[];
    //_playerTwoCannonTop.physicsBody.collisionMask = @[];
    
    // alloc players and bind them to the cannons
    playerOne = [[Player alloc] init];
    playerTwo = [[Player alloc] init];
    playerOne.cannon = _playerOneCannon;
    playerTwo.cannon = _playerTwoCannon;
    playerOne.cannonBase = _playerOneCannonBase;
    playerTwo.cannonBase = _playerTwoCannonBase;
    playerOne.iceBlock = _playerOneIceBlock;
    playerTwo.iceBlock = _playerTwoIceBlock;
    playerOne.movementSpeed = -1;
    playerTwo.movementSpeed = 1;
    playerOne.health = 6;
    playerTwo.health = 6;
    
    //_levelScene = [CCBReader loadAsScene:@"Levels/Level1"];
    //[_levelNode addChild:_levelScene];
    
    _physicsNode.collisionDelegate = self;
    
    // visualize physics bodies & joints
    _physicsNode.debugDraw = FALSE;
    
    // setup some distance variables
    maxPowerDistance = 200.0;
    maxPowerForce = 4000;
    minPowerForce = 1000;
    minDistance = 20;
    
    // initalize the warning borders
    leftBorder = [[CCNodeColor alloc] initWithColor:[CCColor redColor]];
    leftBorder.contentSize = CGSizeMake(10, 320);
    leftBorder.position = [_contentNode convertToWorldSpace:ccp(0,0)];
    leftBorder.visible = NO;
    [_contentNode addChild:leftBorder];
    
    rightBorder = [[CCNodeColor alloc] initWithColor:[CCColor redColor]];
    rightBorder.contentSize = CGSizeMake(10, 320);
    rightBorder.position = [_contentNode convertToWorldSpace:ccp(558,0)];
    rightBorder.visible = NO;
    [_contentNode addChild:rightBorder];
    
    topBorder = [[CCNodeColor alloc] initWithColor:[CCColor redColor]];
    topBorder.contentSize = CGSizeMake(568, 10);
    topBorder.position = [_contentNode convertToWorldSpace:ccp(0,310)];
    topBorder.visible = NO;
    [_contentNode addChild:topBorder];
    
    bottomBorder = [[CCNodeColor alloc] initWithColor:[CCColor redColor]];
    bottomBorder.contentSize = CGSizeMake(568, 10);
    bottomBorder.position = [_contentNode convertToWorldSpace:ccp(0,0)];
    bottomBorder.visible = NO;
    [_contentNode addChild:bottomBorder];
    
    // bind the seals on the level to the players
    //[self bindSealsToPlayers];
    
    // setup the game with fuffr
    [self fuffrSetup];
    
    moveIceBlockTimer = [NSTimer
                        scheduledTimerWithTimeInterval:0.03
                        target:self
                        selector:@selector(moveIceBlock)
                        userInfo:nil
                         repeats:YES];
    
    [self playBackgroundMusic];
}

- (void) fuffrSetup
{
    // Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];
    
    [manager removeAllTouchObserversAndTouchBlocks];
    
	// Set active sides.
    [[FFRTouchManager sharedManager] enableSides: FFRSideRight | FFRSideLeft  touchesPerSide: @1];
	// Register methods for right side touches. The touchEnded
	// method is not used in this example.
    
    [manager
     onFuffrConnected:
     ^{
         [manager useSensorService:
          ^{
              [[FFRTouchManager sharedManager] enableSides: FFRSideRight | FFRSideLeft touchesPerSide:@1];
          }];
     }
     onFuffrDisconnected:
     ^{
     }];
    
    /*
    FFRPanGestureRecognizer* panRight = [FFRPanGestureRecognizer new];
    panRight.side = FFRSideRight;
    [panRight addTarget: self action: @selector(onPanRight:)];
    [manager addGestureRecognizer: panRight];
    
    FFRPanGestureRecognizer* panLeft = [FFRPanGestureRecognizer new];
    panLeft.side = FFRSideLeft;
    [panLeft addTarget: self action: @selector(onPanLeft:)];
    [manager addGestureRecognizer: panLeft];*/
    
    [manager addTouchObserver:self
                   touchBegan:@selector(fuffrTouchBegan:)
                   touchMoved:@selector(fuffrTouchMoved:)
                   touchEnded:@selector(fuffrTouchEnded:)
                        sides:FFRSideLeft | FFRSideRight];
}

#pragma mark - Game Touch Event code

- (void)touchBegan:(CGPoint) touchLocation player:(Player *) player
{
    player.touchStartPoint = touchLocation;
    player.touchEndPoint = touchLocation;
}

- (void)touchMoved:(CGPoint) touchLocation player:(Player *) player
{
    player.touchEndPoint = touchLocation;
    if ([self distanceBetweenPoints:player.touchStartPoint secondPoint:player.touchEndPoint] > minDistance)
    {
        [self rotateCannon:player];
        [self changeColorOfCannon:player];
        [self showWarningBorders:player touchLocation:touchLocation];
    }
}

- (void) touchEnded:(CGPoint) touchLocation player:(Player *) player
{
    player.touchEndPoint = touchLocation;
    if ([self distanceBetweenPoints:player.touchStartPoint secondPoint:player.touchEndPoint] > minDistance)
        [self launchPenguin:player];
}

#pragma mark - IOS Touch Events

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    [self touchBegan:touchLocation player:playerOne];
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    [self touchMoved:touchLocation player:playerOne];
}

- (void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    [self touchEnded:touchLocation player:playerOne];
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self touchEnded:touch withEvent:event];
}

#pragma mark - Fuffr Touch Events

-(void)onPanRight: (FFRPanGestureRecognizer*)gesture
{
    // check the pan gestures state and call the appropriate function for the state
    if (gesture.state == FFRGestureRecognizerStateBegan)
    {
        CGPoint convertXToY = CGPointMake(-gesture.touch.location.y, -gesture.touch.location.x);
        [self touchBegan:convertXToY player:playerOne];
    }
    else if (gesture.state == FFRGestureRecognizerStateChanged)
    {
        CGPoint convertXToY = CGPointMake(-gesture.touch.location.y, -gesture.touch.location.x);
        [self touchMoved:convertXToY player:playerOne];
    }
    else if (gesture.state == FFRGestureRecognizerStateEnded)
    {
        CGPoint convertXToY = CGPointMake(-gesture.touch.location.y, -gesture.touch.location.x);
        [self touchEnded:convertXToY player:playerOne];
    }
}

-(void)onPanLeft: (FFRPanGestureRecognizer*)gesture
{
    // check the pan gestures state and call the appropriate function for the state
    if (gesture.state == FFRGestureRecognizerStateBegan)
    {
        CGPoint convertXToY = CGPointMake(-gesture.touch.location.y, -gesture.touch.location.x);
        [self touchBegan:convertXToY player:playerTwo];
    }
    else if (gesture.state == FFRGestureRecognizerStateChanged)
    {
        CGPoint convertXToY = CGPointMake(-gesture.touch.location.y, -gesture.touch.location.x);
        [self touchMoved:convertXToY player:playerTwo];
    }
    else if (gesture.state == FFRGestureRecognizerStateEnded)
    {
        CGPoint convertXToY = CGPointMake(-gesture.touch.location.y, -gesture.touch.location.x);
        [self touchEnded:convertXToY player:playerTwo];
    }
}

- (void)fuffrTouchBegan:(NSSet *) touches
{
    for (FFRTouch *touch in touches)
    {
        CGPoint convertXToY = CGPointMake(-touch.location.y, -touch.location.x);
        if (touch.side == FFRSideRight)
            [self touchBegan:convertXToY player:playerOne];
        else if (touch.side == FFRSideLeft)
            [self touchBegan:convertXToY player:playerTwo];
    }
}

- (void)fuffrTouchMoved:(NSSet *) touches
{
    for (FFRTouch *touch in touches)
    {
        CGPoint convertXToY = CGPointMake(-touch.location.y, -touch.location.x);
        if (touch.side == FFRSideRight)
            [self touchMoved:convertXToY player:playerOne];
        else if (touch.side == FFRSideLeft)
            [self touchMoved:convertXToY player:playerTwo];
    }
}

- (void)fuffrTouchEnded:(NSSet *) touches
{
    NSLog(@"Touch Ended");
    for (FFRTouch *touch in touches)
    {
        CGPoint convertXToY = CGPointMake(-touch.location.y, -touch.location.x);
        if (touch.side == FFRSideRight)
            [self touchEnded:convertXToY player:playerOne];
        else if (touch.side == FFRSideLeft)
            [self touchEnded:convertXToY player:playerTwo];
    }
}

#pragma mark - Game Calculation And Logic

- (void)launchPenguin:(Player *) player
{
    // create a penguin from the ccb-file
    player.currentPenguin = (Penguin *)[CCBReader load:@"Penguin"];
    
    // turn the penguin around if it is player twos turn
    if (player == playerTwo)
        player.currentPenguin.scaleX = -1.0f;
    
    // initially position it on the cannontip
    CGPoint penguinPosition = [player.cannon convertToWorldSpace:ccp(28, 70)];
    player.currentPenguin.position = penguinPosition;
    
    // add it to the physics world
    [_physicsNode addChild:player.currentPenguin];
    player.currentPenguin.physicsBody.affectedByGravity = false;
    
    // calculate the force to apply to the penguin
    CGFloat force = minPowerForce + ((maxPowerForce - minPowerForce) * [self getPower:player]);
    
    NSLog(@"power = %d%%",(int)([self getPower:player]*100));
    
    [player.currentPenguin.physicsBody applyForce:ccpMult([self getLaunchDirection:player], force)];
    player.currentPenguin.launched = TRUE;
    
    // animate the cannons shot explosion
    __weak CCSprite *cannonShot = (CCSprite *)[CCBReader load:@"Animations/CannonShot"];
    cannonShot.position = [player.cannon convertToWorldSpace:ccp(27, 82)];
    cannonShot.scale = 1.2;
    cannonShot.rotation = player.cannon.rotation;
    [_physicsNode addChild:cannonShot];
    
    // animation removal callback
    [cannonShot.userObject setCompletedAnimationCallbackBlock:^(id sender) {
        [cannonShot removeFromParent];
    }];
    
    // play sound
    [self playSoundCannonShot];
    
    [self changeColorOfCannon:player red:1.0 green:1.0 blue:1.0];
    
    [self hideWarningBorders];
}

- (void)rotateCannon:(Player *) player
{
    if (isnan(90 - [self CGPointToDegree:[self getLaunchDirection:player]]) ||  (90 - [self CGPointToDegree:[self getLaunchDirection:player]]) == INFINITY)
        return;
    player.cannon.rotation = 90 - [self CGPointToDegree:[self getLaunchDirection:player]];
}

- (void)changeColorOfCannon:(Player *) player
{
    CCColor *color;
    if ([self getPower:player] == 0)
        color = [CCColor colorWithRed:1 green:1 blue:1];
    if ([self getPower:player] > 0)
        color = [CCColor colorWithRed:0.3 green:1 blue:0.3];
    if ([self getPower:player] >= 0.5)
        color = [CCColor colorWithRed:1 green:1 blue:0.3];
    if ([self getPower:player] >= 0.9)
        color = [CCColor colorWithRed:1 green:0.3 blue:0.3];
    player.cannon.color = color;
}

- (void)changeColorOfCannon:(Player *) player red:(CGFloat) red green:(CGFloat) green blue:(CGFloat) blue
{
    CCColor *color;
    color = [CCColor colorWithRed:red green:green blue:blue];
    player.cannon.color = color;
}

- (void)playSoundCannonShot
{
    // access audio object
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    
    // play sound effect
    [audio playEffect:@"Sounds/CannonShot.wav" volume:0.7f pitch:1.0f pan:0.0f loop:NO];
}

- (void)playBackgroundMusic
{
    // access audio object
    OALSimpleAudio *audio = [OALSimpleAudio sharedInstance];
    
    // play sound effect
    [audio playBg:@"Background.mp3" volume:0.5f pan:0.0f loop:YES];
}

- (void)moveIceBlock
{
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    float playerOnePos = _playerOneIceBlock.position.y - _playerOneIceBlock.contentSize.width/2;
    float playerTwoPos = _playerTwoIceBlock.position.y - _playerTwoIceBlock.contentSize.width/2;
    
    if (playerOne.movementSpeed > 0)
    {
        if (playerOnePos > screenWidth - (_playerOneIceBlock.contentSize.width+5))
            playerOne.movementSpeed = -1;
    }
    else if (playerOne.movementSpeed < 0)
    {
        if (playerOnePos < 5)
            playerOne.movementSpeed = 1;
    }
    
    if (playerTwo.movementSpeed > 0)
    {
        if (playerTwoPos > screenWidth - (_playerTwoIceBlock.contentSize.width+5))
            playerTwo.movementSpeed = -1;
    }
    else if (playerTwo.movementSpeed < 0)
    {
        if (playerTwoPos < 5)
            playerTwo.movementSpeed = 1;
    }
    
    [playerOne.cannon setPosition:CGPointMake(playerOne.cannon.position.x, playerOne.cannon.position.y+playerOne.movementSpeed)];
    [playerOne.cannonBase setPosition:CGPointMake(playerOne.cannonBase.position.x, playerOne.cannonBase.position.y+playerOne.movementSpeed)];
    [playerOne.iceBlock setPosition:CGPointMake(playerOne.iceBlock.position.x, playerOne.iceBlock.position.y+playerOne.movementSpeed)];
    
    [playerTwo.cannon setPosition:CGPointMake(playerTwo.cannon.position.x, playerTwo.cannon.position.y+playerTwo.movementSpeed)];
    [playerTwo.cannonBase setPosition:CGPointMake(playerTwo.cannonBase.position.x, playerTwo.cannonBase.position.y+playerTwo.movementSpeed)];
    [playerTwo.iceBlock setPosition:CGPointMake(playerTwo.iceBlock.position.x, playerTwo.iceBlock.position.y+playerTwo.movementSpeed)];
}

// not used yet
- (void)addHeartsToPlayer:(Player *) player
{
    CCSprite *heart;
    for (int i = 0; i < player.health; i++)
    {
        heart = (CCSprite *)[CCBReader load:@"Heart"];
        
        [player.heartArray addObject:heart];
    }
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB
{
    float energy = [pair totalKineticEnergy];
    if (energy > 20.f)
        NSLog(@"Energy = %f", energy);
    
    // if energy is large enough, remove the seal
    if (energy > 350.f)
    {
        [[_physicsNode space] addPostStepBlock:^{
            [self removeSeal:nodeA];
        } key:nodeA];
    }
}

- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair iceblock:(CCNode *)nodeA penguin:(CCNode *)nodeB
{
    float energy = [pair totalKineticEnergy];
    if (energy > 20.f)
        NSLog(@"Energy = %f", energy);
    if (energy > 3000.f)
    {
        [[_physicsNode space] addPostStepBlock:^{
            if (nodeA == playerOne.iceBlock)
                [self reduceHealthOfPlayer:playerOne];
            else if (nodeA == playerTwo.iceBlock)
                [self reduceHealthOfPlayer:playerTwo];
        } key:nodeA];
    }
}

/*
- (void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair penguin:(CCNode *)nodeA penguin:(CCNode *)nodeB
{
    float energy = [pair totalKineticEnergy];
    if (energy > 400.f)
    {
        [[_physicsNode space] addPostStepBlock:^{
            [self removePenguin:nodeA];
            [self removePenguin:nodeB];
        } key:nodeA];
    }
}*/

- (void)bindSealsToPlayers
{
    // find the seals in the levelNode and add them to the player arrays
    for (CCNode *tempNode in _levelScene.children)
    {
        if ([tempNode.name isEqualToString:@"levelNode"])
        {
            for (CCNode *seal in tempNode.children)
            {
                if ([seal.name isEqualToString:@"PlayerOne"])
                    [playerOne.sealArray addObject:seal];
                if ([seal.name isEqualToString:@"PlayerTwo"])
                    [playerTwo.sealArray addObject:seal];
            }
        }
    }
}

- (void)removeSeal:(CCNode *) seal
{
    // remove the seal from the player it belongs to
    if ([playerOne.sealArray containsObject:seal])
        [playerOne.sealArray removeObject:seal];
    if ([playerTwo.sealArray containsObject:seal])
        [playerTwo.sealArray removeObject:seal];
    
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"Animations/SealExplosion"];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = TRUE;
    // place the particle effect on the seals position
    explosion.position = seal.position;
    // add the particle effect to the same node the seal is on
    [seal.parent addChild:explosion];
    [seal removeFromParent];
    
    // check for a winner!
}

- (void)removePenguin:(CCNode *) penguin
{
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"Animations/SealExplosion"];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = TRUE;
    // place the particle effect on the penguins position
    explosion.position = penguin.position;
    // add the particle effect to the same node the penguin is on
    [penguin.parent addChild:explosion];
    [penguin removeFromParent];
}

- (void)spriteFlashRed:(CCSprite *) sprite duration:(NSTimeInterval) time
{
    CCActionTintTo *tint1 = [CCActionTintTo actionWithDuration:time/2.0 color:[CCColor colorWithRed:1 green:0.5 blue:0.5]];
    CCActionTintTo *tint2 = [CCActionTintTo actionWithDuration:time/2.0 color:[CCColor colorWithRed:1 green:1 blue:1]];
    CCActionSequence *sequence = [CCActionSequence actionOne:tint1 two:tint2];
    [sprite runAction:sequence];
}

- (void)reduceHealthOfPlayer:(Player *) player
{
    // flash red
    CCSprite *cannon = (CCSprite *) player.cannon;
    CCSprite *cannonTop = [player.cannon.children objectAtIndex:0];
    [self spriteFlashRed:cannonTop duration:0.4];
    [self spriteFlashRed:cannon duration:0.4];
    [self spriteFlashRed:player.iceBlock duration:0.4];
    
    player.health -= 1;
    if (player.health == 0)
    {
        if (!gameOver)
        {
            gameOver = YES;
            [self destroyPlayer:player];
        }
    }
    else if (player.health == 4)
        [player.iceBlock setSpriteFrame:iceBlockWithCracks];
    else if (player.health == 2)
        [player.iceBlock setSpriteFrame:iceBlockWithAlotOfCracks];
}

- (void)destroyPlayer:(Player *) player
{
    CCParticleSystem *explosion;
    for (int i = 0; i < 2 ; i++)
    {
        float ypos = (i*player.iceBlock.contentSize.height/2);
        for (int j = 0; j < 4; j++)
        {
            float xpos = (j*player.iceBlock.contentSize.width/4);
            // load particle effect
            explosion = (CCParticleSystem *)[CCBReader load:@"Animations/SealExplosion"];
            // make the particle effect clean itself up, once it is completed
            explosion.autoRemoveOnFinish = TRUE;
            // place the particle effect on the seals position
            explosion.position = [player.iceBlock convertToWorldSpace:CGPointMake(xpos, ypos)];
            // add the particle effect to the same node the seal is on
            [player.iceBlock.parent addChild:explosion];
        }
    }
    for (int i =0; i < 2; i++)
    {
        explosion = (CCParticleSystem *)[CCBReader load:@"Animations/CannonExplosion"];
        explosion.autoRemoveOnFinish = TRUE;
        // place the particle effect on the seals position
        explosion.position = [player.cannon convertToWorldSpace:CGPointMake(15, 30+(50*i))];
        // add the particle effect to the same node the seal is on
        [player.cannon.parent addChild:explosion];
    }
    [self performSelector:@selector(gameOver) withObject:nil afterDelay:4.0f];
    [[FFRTouchManager sharedManager] removeAllTouchObserversAndTouchBlocks];
    CCLabelTTF *label = (CCLabelTTF *) _midDisplayLabel;
    if (player == playerOne)
        [label setString:@"Player Two Wins!"];
    else [label setString:@"Player One Wins!"];
    label.visible = YES;
}

- (void)gameOver
{
    CCScene *gameplayScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}

- (CGFloat)distanceBetweenPoints: (CGPoint)p1 secondPoint:(CGPoint)p2
{
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    return distance;
}

- (CGPoint)getLaunchDirection:(Player *) player
{
    if (!(isnan([self distanceBetweenPoints:player.touchStartPoint secondPoint:player.touchEndPoint])) || [self distanceBetweenPoints:player.touchStartPoint secondPoint:player.touchEndPoint] != INFINITY)
    {
        // calculate the launch direction
        CGFloat directionCoefficient = 1.0 / ([self distanceBetweenPoints:player.touchStartPoint secondPoint:player.touchEndPoint]);
        CGPoint directionStartPoint = CGPointMake(player.touchStartPoint.x * directionCoefficient, player.touchStartPoint.y * directionCoefficient);
        CGPoint directionEndPoint = CGPointMake(player.touchEndPoint.x * directionCoefficient, player.touchEndPoint.y * directionCoefficient);
        CGPoint launchDirection = ccp((directionEndPoint.x - directionStartPoint.x), (directionEndPoint.y - directionStartPoint.y));

        if (player == playerOne)
        {
            if ([self CGPointToDegree:launchDirection] > 45)
                launchDirection = ccp(1,1);
            else if ([self CGPointToDegree:launchDirection] < -45)
                launchDirection = ccp(1,-1);
        }
        else if (player == playerTwo)
        {
            if ([self CGPointToDegree:launchDirection] > 0 && [self CGPointToDegree:launchDirection] < 135)
                launchDirection = ccp(-1,1);
            if ([self CGPointToDegree:launchDirection] > -135 && [self CGPointToDegree:launchDirection] < 0)
                launchDirection = ccp(-1,-1);
        }
        return launchDirection;
    }
    return ccp(0,0);
}

- (void)showWarningBorders:(Player *) player touchLocation:(CGPoint) touchLocation
{
    float screenHeight = [[UIScreen mainScreen] bounds].size.height;
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    float margin = 55;
    
    if (touchLocation.x < -(screenHeight-margin))
        leftBorder.visible = YES;
    else
        leftBorder.visible = NO;
    if (touchLocation.x > -margin)
        rightBorder.visible = YES;
    else
        rightBorder.visible = NO;
    if (player == playerOne)
    {
        if (touchLocation.y < -(screenWidth - margin))
            bottomBorder.visible = YES;
        else
            bottomBorder.visible = NO;
    }
    else
    {
        if (touchLocation.y > -margin)
            topBorder.visible = YES;
        else
            topBorder.visible = NO;
    }
}

- (void)hideWarningBorders
{
    leftBorder.visible = NO;
    rightBorder.visible = NO;
    topBorder.visible = NO;
    bottomBorder.visible = NO;
}

- (CGFloat)getPower:(Player *) player
{
    // calulcate the power
    CGFloat powerDistance = [self distanceBetweenPoints:player.touchStartPoint secondPoint:player.touchEndPoint];
    
    // constrain the distance to max distance!!
    if (powerDistance > maxPowerDistance)
        powerDistance = maxPowerDistance;
    
    // calculate the power. The value of power is between 0 and 1
    CGFloat powerCoefficient = 1/maxPowerDistance;
    CGFloat power = powerDistance * powerCoefficient;
    return power;
}

- (CGFloat) CGPointToDegree:(CGPoint) point {
    // Provides a directional bearing from (0,0) to the given point
    // standard cartesian plain coords: X goes up, Y goes right
    // result returns degrees, -180 to 180 ish: 0 degrees = up, -90 = left, 90 = right
    CGFloat bearingRadians = atan2f(point.y, point.x);
    CGFloat bearingDegrees = bearingRadians * (180. / M_PI);
    return bearingDegrees;
}

@end
