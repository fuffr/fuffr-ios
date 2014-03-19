//
//  FFRLeftRightSpaceMapper.m
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRLeftRightSpaceMapper.h"

@implementation FFRLeftRightSpaceMapper

-(CGPoint) locationOnScreen:(CGPoint) point fromSide:(FFRCaseSide)side {
    CGSize size = [UIApplication sharedApplication].keyWindow.frame.size;

    CGPoint p = CGPointZero;
    if (side == FFRCaseLeft) {
        p = CGPointMake(size.width * point.x / 2, size.height * point.y);
    }
    else if (side == FFRCaseRight) {
        p = CGPointMake(size.width * (0.5 + point.x / 2), size.height * point.y);
    }

    return p;
}

@end
