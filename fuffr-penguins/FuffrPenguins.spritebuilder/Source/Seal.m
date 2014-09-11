//
//  Seal.m
//  FuffrPenguins
//
//  Created by Fuffr2 on 01/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Seal.h"

@implementation Seal

- (void)didLoadFromCCB {
    self.physicsBody.collisionType = @"seal";
}

@end
