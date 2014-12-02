//
//  AppViewController.h
//  FuffrBox
//
//  Created by Fuffr on 21/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FuffrLib/FFRTouchManager.h>

/**
 * View controller with a web view.
 */
@interface AppViewController : UIViewController<UIWebViewDelegate>

@property NSMutableDictionary* gestureListeners;

- (void) executeJavaScriptCommand: (NSString*) command;

- (void) callJS: (NSString*) code;

@end
