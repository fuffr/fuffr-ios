//
//  Player.h
//  FuffrPenguins
//
//  Created by Fuffr2 on 04/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CCNode.h"
#import "CCSprite.h"
#import "Penguin.h"

@interface Player : NSObject

@property Penguin *currentPenguin;
@property CCNode *cannon, *cannonBase;
@property CCSprite *iceBlock;
@property (strong, nonatomic) NSMutableArray *sealArray, *heartArray;
@property CGPoint touchEndPoint, touchStartPoint;
@property CGFloat movementSpeed;
@property int health;

@end
