//
//  FFRTopBottomSpaceMapper.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRTopBottomSpaceMapper.h"

@implementation FFRTopBottomSpaceMapper

-(CGPoint) locationOnScreen:(CGPoint) point fromSide:(FFRSide)side {
    CGSize size = [UIApplication sharedApplication].keyWindow.frame.size;

    CGPoint p = CGPointZero;
    if (side == FFRSideBottom) {
        p = CGPointMake(size.width * point.x, size.height * (0.5 + point.y / 2));
    }
    else if (side == FFRSideTop) {
        p = CGPointMake(size.width * point.x, size.height * point.y / 2);
    }

    return p;
}

@end
