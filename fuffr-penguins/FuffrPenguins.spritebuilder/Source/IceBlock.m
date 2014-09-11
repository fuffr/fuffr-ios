//
//  IceBlock.m
//  FuffrPenguins
//
//  Created by Fuffr2 on 22/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "IceBlock.h"

@implementation IceBlock

- (void)didLoadFromCCB {
    self.physicsBody.collisionType = @"iceblock";
}

@end
