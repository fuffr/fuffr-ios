//
//  AppViewController.h
//  FuffrDots
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FuffrLib/FFRTouchManager.h>

/**
 * This view controller paints circles for each touch instance.
 */
@interface AppViewController : UIViewController

/** View where touches are drawn. */
@property UIImageView* imageView;

/** Message view. */
@property UILabel* messageView;

@property NSMutableDictionary* dotColors;

@property NSMutableSet* touches;

@end
