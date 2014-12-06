//
//  FFROverlaySpaceMapper.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFROverlaySpaceMapper.h"

@implementation FFROverlaySpaceMapper

-(CGPoint) locationOnScreen:(CGPoint) point fromSide:(FFRSide)side
{
	// Note: On iOS7 the keyWindow.frame is always in portrait
	// orientation, which breaks coordinates. Therefore we use
	// the root view if set, which respects orientation on
	// both iOS 7 and iOS 8.
	UIViewController* rootViewController =
		[[[UIApplication sharedApplication] keyWindow]
				rootViewController];
	UIView* rootView = rootViewController.view;
	CGSize size;
	if (nil != rootView)
	{
		size = rootViewController.view.bounds.size;
	}
    else
	{
		size = [UIApplication sharedApplication].keyWindow.frame.size;
	}
    CGPoint p = CGPointMake(size.width * point.x, size.height * point.y);
    return p;
}

@end
