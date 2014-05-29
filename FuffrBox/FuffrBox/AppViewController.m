//
//  AppViewController.m
//  FuffrBox
//
//  Created by Fuffr on 21/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "AppViewController.h"

#import <FuffrLib/FFRTapGestureRecognizer.h>
#import <FuffrLib/FFRLongPressGestureRecognizer.h>
#import <FuffrLib/FFRSwipeGestureRecognizer.h>
#import <FuffrLib/FFRPinchGestureRecognizer.h>
#import <FuffrLib/FFRPanGestureRecognizer.h>
#import <FuffrLib/FFRRotationGestureRecognizer.h>
#import <FuffrLib/FFRFirmwareDownloader.h>
#import <FuffrLib/FFROADHandler.h>
#import <FuffrLib/UIView+Toast.h>

/**
 * Reference to the AppViewController instance.
 */
static AppViewController* theAppViewController;

/**
 * Could not resist shortcut using a global.
 */
static BOOL FuffrIsConnected = NO;

/**
 * Bridge from JavaScript to Objective-C.
 */
@interface URLProtocolFuffrBridge : NSURLProtocol
@end

@implementation URLProtocolFuffrBridge

+ (BOOL)canInitWithRequest:(NSURLRequest*)theRequest
{
	NSRange range = [theRequest.URL.path rangeOfString: @"/fuffr-bridge@"];
    BOOL found = (range.location != NSNotFound);
	return found;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
	return theRequest;
}

- (void)startLoading
{
	NSString* path = self.request.URL.path;

	[theAppViewController executeJavaScriptCommand: path];

	NSDictionary* headers = @{
		@"Access-Control-Allow-Origin" : @"*",
		@"Access-Control-Allow-Headers" : @"Content-Type"
	};

	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
		initWithURL: self.request.URL
		statusCode: 200
		HTTPVersion: @"1.1"
		headerFields: headers];

	NSData* data = [@"OK" dataUsingEncoding: NSUTF8StringEncoding];

	/*NSURLResponse* response = [[NSURLResponse alloc]
		initWithURL: self.request.URL
		MIMEType: @"text/plain"
		expectedContentLength: -1
		textEncodingName: nil];*/
	[[self client]
		URLProtocol: self
		didReceiveResponse: response
		cacheStoragePolicy: NSURLCacheStorageNotAllowed];
	[[self client] URLProtocol: self didLoadData: data];
	[[self client] URLProtocolDidFinishLoading: self];

	/*[[self client]
			URLProtocol: self
			didFailWithError: createError()];*/
}

- (void)stopLoading
{
}

@end

/**
 * Gesture listener.
 */
@interface GestureListener : NSObject

@property int gestureId;
@property (nonatomic, strong) FFRGestureRecognizer* recognizer;
@property (nonatomic, weak) AppViewController* controller;

+ (GestureListener*) withGestureId: (int) gestureId
	type: (int) type
	side: (FFRSide) side
	controller: (AppViewController*) theController;

- (void) onPan: (FFRPanGestureRecognizer*) recognizer;
- (void) onPinch:(FFRPinchGestureRecognizer*) recognizer;
- (void) onRotation:(FFRRotationGestureRecognizer*) recognizer;
- (void) onTap:(FFRTapGestureRecognizer*) recognizer;
//- (void) onDoubleTap:(FFRDoubleTapGestureRecognizer*) recognizer;
- (void) onLongPress:(FFRLongPressGestureRecognizer*) recognizer;
- (void) onSwipe:(FFRSwipeGestureRecognizer*) recognizer;

@end

@implementation GestureListener

+ (GestureListener*) withGestureId: (int) gestureId
	type: (int) type
	side: (FFRSide) side
	controller: (AppViewController*) theController
{
	GestureListener* me = [GestureListener new];

	me.gestureId = gestureId;
	me.controller = theController;

	if (1 == type)
	{
		me.recognizer = [FFRPanGestureRecognizer new];
    	[me.recognizer
			addTarget: me
			action: @selector(onPan:)];
	}
	else if (2 == type)
	{
		me.recognizer = [FFRPinchGestureRecognizer new];
    	[me.recognizer
			addTarget: me
			action: @selector(onPinch:)];
	}
	else if (3 == type)
	{
		me.recognizer = [FFRRotationGestureRecognizer new];
    	[me.recognizer
			addTarget: me
			action: @selector(onRotation:)];
	}
	else if (4 == type)
	{
		me.recognizer = [FFRTapGestureRecognizer new];
    	[me.recognizer
			addTarget: me
			action: @selector(onTap:)];
	}
	else if (5 == type)
	{
		// TODO: Implement.
		//me.recognizer = [FFRDoubleTapGestureRecognizer new];
	}
	else if (6 == type)
	{
		me.recognizer = [FFRLongPressGestureRecognizer new];
    	[me.recognizer
			addTarget: me
			action: @selector(onLongPress:)];
	}
	else if (7 == type)
	{
		FFRSwipeGestureRecognizer* swipe = [FFRSwipeGestureRecognizer new];
		swipe.direction = UISwipeGestureRecognizerDirectionLeft;
		me.recognizer = swipe;
    	[me.recognizer
			addTarget: me
			action: @selector(onSwipe:)];
	}
	else if (8 == type)
	{
		FFRSwipeGestureRecognizer* swipe = [FFRSwipeGestureRecognizer new];
		swipe.direction = UISwipeGestureRecognizerDirectionRight;
		me.recognizer = swipe;
    	[me.recognizer
			addTarget: me
			action: @selector(onSwipe:)];
	}
	else if (9 == type)
	{
		FFRSwipeGestureRecognizer* swipe = [FFRSwipeGestureRecognizer new];
		swipe.direction = UISwipeGestureRecognizerDirectionUp;
		me.recognizer = swipe;
    	[me.recognizer
			addTarget: me
			action: @selector(onSwipe:)];
	}
	else if (10 == type)
	{
		FFRSwipeGestureRecognizer* swipe = [FFRSwipeGestureRecognizer new];
		swipe.direction = UISwipeGestureRecognizerDirectionDown;
		me.recognizer = swipe;
    	[me.recognizer
			addTarget: me
			action: @selector(onSwipe:)];
	}

	me.recognizer.side = side;

	[[FFRTouchManager sharedManager] addGestureRecognizer: me.recognizer];

	return me;
}

- (void) onPan: (FFRPanGestureRecognizer*) recognizer
{
	NSString* code = [NSString stringWithFormat:
		@"fuffr.internal.performCallback(%i,%i,%f,%f)",
		self.gestureId,
		recognizer.state,
		recognizer.translation.width,
		recognizer.translation.height];
	[self.controller callJS: code];
}

- (void) onPinch:(FFRPinchGestureRecognizer*) recognizer
{
	NSString* code = [NSString stringWithFormat:
		@"fuffr.internal.performCallback(%i,%i,%f)",
		self.gestureId,
		recognizer.state,
		recognizer.scale];
	[self.controller callJS: code];
}

- (void) onRotation:(FFRRotationGestureRecognizer*) recognizer
{
	NSString* code = [NSString stringWithFormat:
		@"fuffr.internal.performCallback(%i,%i,%f)",
		self.gestureId,
		recognizer.state,
		recognizer.rotation];
	[self.controller callJS: code];
}

- (void) onTap:(FFRTapGestureRecognizer*) recognizer
{
	NSString* code = [NSString stringWithFormat:
		@"fuffr.internal.performCallback(%i,%i)",
		self.gestureId,
		recognizer.state];
	[self.controller callJS: code];
}

- (void) onLongPress:(FFRLongPressGestureRecognizer*) recognizer
{
	NSString* code = [NSString stringWithFormat:
		@"fuffr.internal.performCallback(%i,%i)",
		self.gestureId,
		recognizer.state];
	[self.controller callJS: code];
}

- (void) onSwipe:(FFRSwipeGestureRecognizer*) recognizer
{
	NSString* code = [NSString stringWithFormat:
		@"fuffr.internal.performCallback(%i,%i)",
		self.gestureId,
		recognizer.state];
	[self.controller callJS: code];
}

@end

@implementation AppViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Add custom initialization if needed.
    }

	//[[NSURLCache sharedURLCache] removeAllCachedResponses];

	//NSURLCache *sharedCache = [[NSURLCache alloc]
	//	initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
	//[NSURLCache setSharedURLCache: sharedCache];

	// Global reference to the AppViewController instance.
	theAppViewController = self;

	self.gestureListeners = [NSMutableDictionary new];

    return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	CGRect bounds;

	CGRect viewBounds = self.view.bounds;

	CGFloat toolbarOffsetY = 0;
	CGFloat toolbarHeight = 40;

	// Back button.

	UIButton* buttonBack = [UIButton buttonWithType: UIButtonTypeSystem];
    [buttonBack setFrame: CGRectMake(3, toolbarOffsetY, 40, toolbarHeight)];
	[buttonBack setTitle: @"Back" forState: UIControlStateNormal];
	[buttonBack
		addTarget: self
		action: @selector(onButtonBack:)
		forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: buttonBack];

	// URL field.

	bounds = CGRectMake(50, toolbarOffsetY + 1, 0, toolbarHeight);
	bounds.size.width = viewBounds.size.width - 90;
	self.urlField = [[UITextField alloc] initWithFrame: bounds];
	[self setSavedURL];
	self.urlField.clearButtonMode = UITextFieldViewModeNever;
	[self.urlField setKeyboardType: UIKeyboardTypeURL];
	self.urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview: self.urlField];

	// Go button.

	bounds = CGRectMake(0, toolbarOffsetY, 40, toolbarHeight);
	bounds.origin.x = viewBounds.size.width - 40;
	UIButton* buttonGo = [UIButton buttonWithType: UIButtonTypeSystem];
    [buttonGo setFrame: bounds];
	[buttonGo setTitle: @"Go" forState: UIControlStateNormal];
	[buttonGo
		addTarget: self
		action: @selector(onButtonGo:)
		forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: buttonGo];

	// Web view.

	bounds = viewBounds;
	//bounds = CGRectOffset(bounds, 0, 20);
	//bounds = CGRectInset(bounds, 0, 50);
	bounds.origin.y = toolbarHeight;
	bounds.size.height -= bounds.origin.y;

	self.webView = [[UIWebView alloc] initWithFrame: bounds];

	// Set properties of the web view.
    self.webView.autoresizingMask =
		UIViewAutoresizingFlexibleHeight |
		UIViewAutoresizingFlexibleWidth;
	self.webView.scalesPageToFit = NO; //YES;
	// http://stackoverflow.com/questions/2442727/strange-padding-margin-when-using-uiwebview
	// http://stackoverflow.com/questions/18947872/ios7-added-new-whitespace-in-uiwebview-removing-uiwebview-whitespace-in-ios7
	self.automaticallyAdjustsScrollViewInsets = NO;
	self.webView.scrollView.bounces = NO;
	self.view.multipleTouchEnabled = YES;
	[self.webView setBackgroundColor:[UIColor greenColor]];

    [self.view addSubview: self.webView];

	[NSURLProtocol registerClass: [URLProtocolFuffrBridge class]];

	// Set URL to local start page.
	NSString* path = [[NSBundle mainBundle]
		pathForResource:@"index" ofType:@"html" inDirectory:@"www"];
	NSURL* url = [NSURL fileURLWithPath:path isDirectory:NO];

	//[self.webView loadHTMLString:@"<html><body style='background:rgb(100,200,255);font-family:sans-serif;'><h1>Welcome to FuffrBox</h1><h3>Play games and make your own apps for Fuffr!</h3><h3>Enter url to page and select go.</h3></body></html>" baseURL:nil];

	// Connect to Evothings Studio.
	//NSURL* url = [NSURL URLWithString:@"http://192.168.43.131:4042"];

	// Load URL into web view.
	NSURLRequest* request = [NSURLRequest
		requestWithURL: url
		cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData
		timeoutInterval: 10];
	[self.webView loadRequest: request];
}

#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"

-(void) enableWebGL
{
	id webDocumentView = [self.webView performSelector: @selector(_browserView)];
    id backingWebView = [webDocumentView performSelector: @selector(webView)];

	// Cannot use performSelector: since _setWebGLEnabled: takes
	// a primitibe BOOL param. Therefore using NSInvocation.
	// Compiler raises error if sending _setWebGLEnabled: in the normal way.
	SEL selector = NSSelectorFromString(@"_setWebGLEnabled:");
	BOOL flag = YES;
	void* value = &flag;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
		[backingWebView methodSignatureForSelector: selector]];
    [invocation setSelector: selector];
    [invocation setTarget: backingWebView];
    [invocation setArgument: value atIndex: 2];
    [invocation invoke];
}

#pragma clang diagnostic pop

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

	[self enableWebGL];

	// Connect to Fuffr and setup touch events.
	[self setupFuffr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupFuffr
{
	[self connectToFuffr];
	[self setupTouches];
}

- (void) connectToFuffr
{
	[self.view makeToast: @"Scanning for Fuffr"];

	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Set connected and disconnected action blocks.
	[manager
		onFuffrConnected:
		^{
			[manager useSensorService:
			^{
				NSLog(@"Fuffr Connected");
				[self.view makeToast: @"Fuffr Connected"];
				/* TODO: Let the apps enable sides in JavaScript instead. */
				[manager
					enableSides: FFRSideTop | FFRSideLeft | FFRSideRight | FFRSideBottom
					touchesPerSide: @2 // Default number of touches per side.
					];
				FuffrIsConnected = YES;
				[self callJS: @"fuffr.on.connected()"];
			}];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"Fuffr Disconnected");
			[self.view makeToast: @"Fuffr Disconnected"];
			FuffrIsConnected = NO;
			[self callJS: @"fuffr.on.disconnected()"];
		}];
}

- (void) setupTouches
{
	//[[FFRTouchManager sharedManager] unregisterTouchMethods];

    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(touchesBegan:)
		name: FFRTrackingBeganNotification
		object: nil];
    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(touchesMoved:)
		name: FFRTrackingMovedNotification
		object: nil];
    [[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(touchesEnded:)
		name: FFRTrackingEndedNotification
		object: nil];
}

- (void) executeJavaScriptCommand: (NSString*) command
{
	NSArray* tokens = [command componentsSeparatedByString:@"@"];
	NSString* commandName = [NSString stringWithString:[tokens objectAtIndex: 1]];

	NSLog(@"executeJavaScriptCommand: %@", command);

	if ([commandName isEqualToString: @"domLoaded"])
	{
		[self jsCommandDomLoaded: tokens];
	}
	else if ([commandName isEqualToString: @"enableSides"])
	{
		[self jsCommandEnableSides: tokens];
	}
	else if ([commandName isEqualToString: @"addGesture"])
	{
		[self jsCommandAddGesture: tokens];
	}
	else if ([commandName isEqualToString: @"removeGesture"])
	{
		[self jsCommandRemoveGesture: tokens];
	}
	else if ([commandName isEqualToString: @"updateFirmware"])
	{
		[self jsCommandUpdateFirmware: tokens];
	}
	else if ([commandName isEqualToString: @"consoleLog"])
	{
		[self jsCommandConsoleLog: tokens];
	}
}

- (void) jsCommandDomLoaded: (NSArray*) tokens
{
	if (FuffrIsConnected)
	{
		[self callJS: @"fuffr.on.connected()"];
	}
}

- (void) jsCommandEnableSides: (NSArray*) tokens
{
	NSString* sides = [NSString stringWithString:[tokens objectAtIndex: 2]];
	NSString* touches = [NSString stringWithString:[tokens objectAtIndex: 3]];
	[[FFRTouchManager sharedManager]
		enableSides: (FFRSide)[sides intValue]
		touchesPerSide: [NSNumber numberWithInt: [touches intValue]]];
}

- (void) jsCommandAddGesture: (NSArray*) tokens
{
	NSString* gestureType = [NSString stringWithString:[tokens objectAtIndex: 2]];
	NSString* gestureSide = [NSString stringWithString:[tokens objectAtIndex: 3]];
	NSString* gestureId = [NSString stringWithString:[tokens objectAtIndex: 4]];

	int type = [gestureType intValue];
	FFRSide side = [gestureSide intValue];
	int gestId = [gestureId intValue];

	// TODO: handle invalid values for type & side.
	GestureListener* gesture = [GestureListener
		withGestureId: gestId
		type: type
		side: side
		controller: self];

	[self.gestureListeners setObject: gesture forKey: gestureId];
}

- (void) jsCommandRemoveGesture: (NSArray*) tokens
{
	NSString* gestureId = [NSString stringWithString:[tokens objectAtIndex: 2]];

	// Remove gesture from list of gesture listeners.
	[self.gestureListeners removeObjectForKey: gestureId];
}

- (void) jsCommandRemoveAllGestures: (NSArray*) tokens
{
	[self.gestureListeners removeAllObjects];
}

// TODO: Implement.
- (void) jsCommandUpdateFirmware: (NSArray*) tokens
{
	FFRBLEManager* bleManager = [FFRBLEManager sharedManager];

	// Turn off and release case handler.
	id currentHandler = bleManager.handler;
	bleManager.handler = nil;
	[currentHandler shutDown];

	// Set up OAD handler.
	FFROADHandler* handler = [FFROADHandler alloc];
	[handler setPeripheral: [bleManager connectedPeripheral]];

	// Set the handler.
	bleManager.handler = handler;
	[bleManager.handler useImageVersionService:
	^{
		NSLog(@"Found image version service");

		// Get firmware image version to download.
		[handler queryCurrentImageVersion: ^void (char version)
		{
			NSLog(@"*** Image type is: %c", version);
			// TODO: Proceed with download.
		}];
	}];

	/*
	[[FFRFirmwareDownloader new]
		downloadFirmwareDataFromURL: @"http://divineprog.com/"
		callback: ^void(NSData* data)
		{
			if (data)
			{
				NSString* text = [[NSString alloc]
					initWithData: data
					encoding: NSUTF8StringEncoding];
            	NSLog(@"Data: %@",text);
        	}
		}];
	*/
}

- (void) jsCommandConsoleLog: (NSArray*) tokens
{
	NSString* message = [NSString stringWithString:[tokens objectAtIndex: 2]];
	NSLog(@"%@", message);
}

- (void) onButtonBack: (id)sender
{
	[self.webView goBack];
}

- (void) onButtonGo: (id)sender
{
	[self.view endEditing: YES];

	NSString* urlString = self.urlField.text;

	if (![urlString hasPrefix: @"http://"])
	{
		urlString = [NSString stringWithFormat:@"http://%@", urlString];
	}

	[self saveURL: urlString];

	NSURL* url = [NSURL URLWithString: urlString];
	NSURLRequest* request = [NSURLRequest
		requestWithURL: url
		cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData
		timeoutInterval: 10];
	[self.webView loadRequest: request];
}

- (void) saveURL: (NSString*)url
{
	[[NSUserDefaults standardUserDefaults]
		setObject: url
		forKey: @"FuffrBoxSavedURL"];
}

- (void) setSavedURL
{
	NSString* url = [[NSUserDefaults standardUserDefaults]
		stringForKey: @"FuffrBoxSavedURL"];
	if (url)
	{
		self.urlField.text = url;
	}
	else
	{
		self.urlField.text = @"fuffr.com";
	}
}

- (void) touchesBegan: (NSNotification*)data
{
    NSSet* touches = data.object;
	[self callJS: @"fuffr.on.touchesBegan" withTouches: touches];
}

- (void) touchesMoved: (NSNotification*)data
{
    NSSet* touches = data.object;
	[self callJS: @"fuffr.on.touchesMoved" withTouches: touches];
}

- (void) touchesEnded: (NSNotification*)data
{
    NSSet* touches = data.object;
	[self callJS: @"fuffr.on.touchesEnded" withTouches: touches];
}

// Example call: fuffr.on.touchesBegan([{...},{...},...])
- (void) callJS: (NSString*) functionName withTouches: (NSSet*) touches
{
	NSString* script = [NSString stringWithFormat:
		@"try{%@(%@)}catch(err){}",
		functionName,
		[self touchesAsJsArray: touches]];
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self.webView stringByEvaluatingJavaScriptFromString: script];
    });
}

- (void) callJS: (NSString*) code
{
	NSString* script = [NSString stringWithFormat:
		@"try{%@}catch(err){}",
		code];
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self.webView stringByEvaluatingJavaScriptFromString: script];
    });
}

- (NSString*) touchesAsJsArray: (NSSet*) touches
{
	NSMutableString* arrayString = [NSMutableString stringWithCapacity: 300];

	[arrayString appendString: @"["];

	int counter = (int)touches.count;
	for (FFRTouch* touch in touches)
	{
		[arrayString appendString: [self touchAsJsObject: touch]];
		if (--counter > 0)
		{
			[arrayString appendString: @","];
		}
	}

	[arrayString appendString: @"]"];

	return arrayString;
}

- (NSString*) touchAsJsObject: (FFRTouch*)touch
{
	return [NSString stringWithFormat:
		@"{id:%d,side:%d,x:%f,y:%f,prevx:%f,prevy:%f,normx:%f,normy:%f}",
		(int)touch.identifier,
		touch.side,
		touch.location.x,
		touch.location.y,
		touch.previousLocation.x,
		touch.previousLocation.y,
		touch.normalizedLocation.x,
		touch.normalizedLocation.y];
}

@end
