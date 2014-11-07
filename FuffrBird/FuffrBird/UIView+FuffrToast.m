//
//  UIView+FuffrToast.m
//  FuffrBeats
//
//  Created by Fuffr2 on 07/11/14.
//  Copyright (c) 2014 BraidesAppHouse. All rights reserved.
//

#import "UIView+FuffrToast.h"

@implementation UIView (FuffrToast)

- (void)makeFuffrConnectedToast
{
    [self showFuffrStatusToast:@"Connected" atPosition:nil centered:NO];
}

- (void)makeFuffrDisconnectedToast
{
    [self showFuffrStatusToast:@"Disconnected" atPosition:nil centered:NO];
}

- (void)makeFuffrConnectedToastAtPosition:(CGPoint) position asCenter:(BOOL) centered
{
    NSValue *pointValue = [NSValue valueWithCGPoint:position];
    [self showFuffrStatusToast:@"Connected" atPosition:pointValue centered:centered];
}

- (void)makeFuffrDisconnectedToastAtPosition:(CGPoint) position asCenter:(BOOL) centered
{
    NSValue *pointValue = [NSValue valueWithCGPoint:position];
    [self showFuffrStatusToast:@"Disconnected" atPosition:pointValue centered:centered];
}

- (void)showFuffrStatusToast:(NSString *) status atPosition:(id) position centered:(BOOL) positionAsCenter
{
    float screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat offset = 13.0;
    CGSize toastSize = CGSizeMake(150, 30);
    CGPoint toastPosition;
    
    if (position != nil)
    {
        NSValue *point = position;
        toastPosition = point.CGPointValue;
    }
    else
    {
        toastPosition = CGPointMake(offset, screenHeight-offset-toastSize.height);
    }
    
    NSLog(@"screenheight = %.f", screenHeight);
    
    UIImageView *toastView = [[UIImageView alloc] initWithFrame:CGRectMake(toastPosition.x, toastPosition.y, toastSize.width, toastSize.height)];
    
    if ([status containsString:@"Disconnected"])
    {
        toastView.frame = CGRectMake(toastView.frame.origin.x, toastView.frame.origin.y, toastView.frame.size.width *1.2, toastView.frame.size.height);
    }
    
    if (positionAsCenter)
        toastView.center = toastPosition;
    
    toastView.image = [UIImage imageNamed:[@"Fuffr " stringByAppendingString:[status stringByAppendingString:@".png"]]];
    toastView.alpha = 0.0;
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:toastView];
    
    [[toastView class] animateWithDuration:1.0 delay:0.0 options:(UIViewAnimationOptionCurveEaseOut) animations:
     ^{
         toastView.alpha = 1.0;
     }completion:^(BOOL finished)
     {
         [self performSelector:@selector(hideFuffrStatusToast:) withObject:toastView afterDelay:1.5];
     }];
}

- (void)hideFuffrStatusToast:(UIImageView *) toastView
{
    [[toastView class] animateWithDuration:1.0 delay:0.0 options:(UIViewAnimationOptionCurveEaseIn) animations:
     ^{
         toastView.alpha = 0.0;
     }completion:^(BOOL finished)
     {
         [toastView removeFromSuperview];
     }];
}

@end
