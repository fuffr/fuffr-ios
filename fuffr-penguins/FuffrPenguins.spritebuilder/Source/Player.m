//
//  Player.m
//  FuffrPenguins
//
//  Created by Fuffr2 on 04/08/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Player.h"

@implementation Player

- (NSMutableArray *) sealArray
{
    if (!_sealArray) {
        _sealArray = [[NSMutableArray alloc] init];
    }
    return _sealArray;
}

@end
