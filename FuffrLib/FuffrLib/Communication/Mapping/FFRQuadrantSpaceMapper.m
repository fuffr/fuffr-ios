//
//  FFRQuadrantSpaceMapper.m
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRQuadrantSpaceMapper.h"

@implementation FFRQuadrantSpaceMapper

-(CGPoint) locationOnScreen:(CGPoint) point fromSide:(FFRCaseSide)side {
    CGSize size = [UIApplication sharedApplication].keyWindow.frame.size;

    CGPoint p = CGPointZero;
    if (side == FFRCaseTop) {
        p = CGPointMake(size.width * (0.5 + point.x / 2), size.height * point.y / 2);
    }
    else if (side == FFRCaseRight) {
        p = CGPointMake(size.width * (0.5 + point.x / 2), size.height * (0.5 +point.y / 2));
    }
    else if (side == FFRCaseBottom) {
        p = CGPointMake(size.width * point.x, size.height * (0.5 + point.y / 2));
    }
    else if (side == FFRCaseLeft) {
        p = CGPointMake(size.width * point.x / 2, size.height * point.y / 2);
    }

    return p;
}

@end
