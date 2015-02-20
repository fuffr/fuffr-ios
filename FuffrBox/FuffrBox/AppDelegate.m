//
//  AppDelegate.m
//  FuffrBox
//
//  Created by miki on 02/04/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "AppDelegate.h"
#import "AppViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Set window size and color.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    // Create and display the view controller.
    AppViewController* viewController = [AppViewController new];
	self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // First, we'll extract the list of parameters from the URL
    NSString* URLstring = [url absoluteString];
    NSArray *strURLParse = [URLstring componentsSeparatedByString:@"//"];
    if ([strURLParse count] == 2) {
        for (int i = 0; i < strURLParse.count; i++)
        {
            NSRange range = [[strURLParse objectAtIndex:i ]  rangeOfString:@"fuffrbox:"];
            if (range.length != 7)
            {
                NSString *urlString = [@"http://" stringByAppendingString:[strURLParse objectAtIndex:i ]];
                NSURL* passedUrl = [NSURL URLWithString: urlString];
                NSLog(@"passedURL = %@", passedUrl);
                NSURLRequest* request = [NSURLRequest
                                         requestWithURL: passedUrl
                                         cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                         timeoutInterval: 10];
                AppViewController * viewController = (AppViewController *)self.window.rootViewController;
                [viewController.webView loadRequest:request];
            }
        }
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

	[[FFRTouchManager sharedManager] disconnectFuffr];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
	[[FFRTouchManager sharedManager] reconnectFuffr];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
