//
//  FFROverlaySpaceMapper.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFROverlaySpaceMapper.h"

@implementation FFROverlaySpaceMapper

-(CGPoint) locationOnScreen:(CGPoint) point fromSide:(FFRSide)side {
    CGSize size = [UIApplication sharedApplication].keyWindow.frame.size;
    CGPoint p = CGPointMake(size.width * point.x, size.height * point.y);

    return p;
}

@end
