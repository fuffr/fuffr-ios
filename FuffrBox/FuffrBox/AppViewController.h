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
@interface AppViewController : UIViewController<UIWebViewDelegate, UIGestureRecognizerDelegate>

/** The web view. */
@property UIWebView* webView;

/** The url field. */
@property UITextField* urlField;

@property NSMutableDictionary* gestureListeners;

- (void) executeJavaScriptCommand: (NSString*) command;

- (void) callJS: (NSString*) code;

@end
