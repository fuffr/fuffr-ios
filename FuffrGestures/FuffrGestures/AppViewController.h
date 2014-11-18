//
//  AppViewController.h
//  FuffrGestures
//
//  Created by Fuffr on 21/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FuffrLib/FFRTouchManager.h>

/**
 * View controller that displays an object controlled by gestures.
 */
@interface AppViewController : UIViewController <UIGestureRecognizerDelegate>

/** View where gestures are drawn. */
@property UIImageView *imageView, *rightEyeImageView, *leftEyeImageView;

/** Message view. */
@property UILabel *messageView;

/** Translation. */
@property CGPoint startPoint;
@property NSString *degrees;

/** Scale. */
@property CGFloat currentScale;
@property CGFloat baseScale;

/** Rotation. */
@property CGFloat currentRotation;
@property CGFloat baseRotation;

@property CGFloat offsetSize;

@property int fuffrGuyFlight;

@property NSTimer *fuffrGuyMovement;

@property BOOL paning, pinchRotateActive, tapCooldown, longPressCooldown;

@property NSMutableArray *explodeAnimationArray;

@end
