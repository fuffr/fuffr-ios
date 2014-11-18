//
//  UIView+FuffrToast.h
//  FuffrBeats
//
//  Created by Fuffr2 on 07/11/14.
//  Copyright (c) 2014 BraidesAppHouse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FuffrToast)

- (void)makeFuffrConnectedToast;
- (void)makeFuffrConnectedToastAtPosition:(CGPoint) position asCenter:(BOOL) centered;
- (void)makeFuffrDisconnectedToast;
- (void)makeFuffrDisconnectedToastAtPosition:(CGPoint) position asCenter:(BOOL) centered;

@end
