//
//  AppViewController.h
//  FuffrDots
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FuffrLib/FFRTouchManager.h>
#import "EAGLView.h"

/**
 * This view controller paints circles for each touch instance.
 */
@interface AppViewController : UIViewController<UIActionSheetDelegate>

/** View where touches are drawn. */
@property EAGLView* glView;

@property UILabel* messageView;

@property UIButton* buttonSettings;

@property UIActionSheet* actionSheet;

@property NSMutableDictionary* dotColors;

@property BOOL paintModeOn;

/** Current set of touces. */
@property NSMutableSet* touches;

@end
