//
//  AppViewController.h
//  FuffrGesutres
//
//  Created by Fuffr on 21/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FuffrLib/FFRTouchManager.h>

typedef struct
{
	CGFloat red;
	CGFloat green;
	CGFloat blue;
}
MyColor;

/**
 * View controller that displays an object controlled by gestures.
 */
@interface AppViewController : UIViewController

/** View where gestures are drawn. */
@property UIImageView* imageView;

/** Translation. */
@property CGPoint currentTranslation;
@property CGPoint baseTranslation;

/** Scale. */
@property CGFloat currentScale;
@property CGFloat baseScale;

/** Rotation. */
@property CGFloat currentRotation;
@property CGFloat baseRotation;

/** Color. */
@property MyColor objectColor;

@end
