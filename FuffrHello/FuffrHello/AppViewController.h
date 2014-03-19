//
//  AppViewController.h
//  Header file for the FuffrHello view controller.
//
//  Created by miki on 16/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FuffrLib/FFRTouchManager.h>

/**
 * This view controller paints two circles, which are
 * tracked by the left and right side of the case.
 */
@interface AppViewController : UIViewController

/** View where circles are drawn. */
@property UIImageView* imageView;

/** Coordinates and size of the circles. */
@property CGFloat circleRightX;
@property CGFloat circleRightY;
@property CGFloat circleLeftX;
@property CGFloat circleLeftY;
@property CGFloat circleSize;

/** Reference to right side touch. */
@property (nonatomic, weak) FFRTouch* touchRight;

/** Reference to left side touch. */
@property (nonatomic, weak) FFRTouch* touchLeft;

@end
