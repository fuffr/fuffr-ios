//
//  Penguin.m
//  FuffrPenguins
//
//  Created by Fuffr2 on 01/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Penguin.h"

@implementation Penguin

- (void)didLoadFromCCB {
    self.physicsBody.collisionType = @"penguin";
}

@end
