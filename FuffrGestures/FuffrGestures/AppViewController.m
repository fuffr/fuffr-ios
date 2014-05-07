//
//  AppViewController.m
//  FuffrGestures
//
//  Created by Fuffr on 21/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

/*
How to use
----------

The app has two states. You swithing between states by 
long pressing the bottom side of Fuffr. The Face will
change color to indicate the current state.

State 1 has the following gestures:

  Right side:
    Pinch and Rotate
	Double tap to set random face color
	Long-press to reset face
  Left side: 
    Pan
	Double tap to set random face color
	Long-press to reset face
  Bottom side: 
    Tap to switch state

State 2 has the following gestures:

  Right side:
    Swipe left/right/up/down to move face to the sides
	Double tap to set random face color
	Long-press to reset face
  Left side: 
    Pan
	Double tap to set random face color
	Long-press to reset face
  Bottom side: 
    Tap to switch state
*/

#import "AppViewController.h"

#import <FuffrLib/FFRTapGestureRecognizer.h>
#import <FuffrLib/FFRDoubleTapGestureRecognizer.h>
#import <FuffrLib/FFRLongPressGestureRecognizer.h>
#import <FuffrLib/FFRSwipeGestureRecognizer.h>
#import <FuffrLib/FFRPinchGestureRecognizer.h>
#import <FuffrLib/FFRPanGestureRecognizer.h>
#import <FuffrLib/FFRRotationGestureRecognizer.h>

@implementation AppViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		// Add custom initialization if needed.
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	// Create an image view for drawing.
	self.imageView = [[UIImageView alloc] initWithFrame: self.view.bounds];
	self.imageView.autoresizingMask =
		UIViewAutoresizingFlexibleHeight |
		UIViewAutoresizingFlexibleWidth;
	[self.view addSubview: self.imageView];

	// Set background color.
	self.imageView.backgroundColor = [UIColor
		colorWithRed: 1.0
		green: 1.0
		blue: 0.7
		alpha: 1.0];

	self.view.multipleTouchEnabled = YES;
}

-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear: animated];

	[self setupFuffr];
	[self initializeRenderingParameters];
	[self redrawImageView];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

-(void) initializeRenderingParameters
{
	self.baseTranslation = CGPointMake(0.0, 0.0);
	self.currentTranslation = self.baseTranslation;

	self.baseScale = 1.0;
	self.currentScale = self.baseScale;

	self.baseRotation = 0.0;
	self.currentRotation = self.baseRotation;

	[self setFaceColor1];
}

-(void) setFaceColor1
{
	MyColor color;
	color.red = 0.0;
	color.green = 1.0;
	color.blue = 0.0;
	self.objectColor = color;
}

-(void) setFaceColor2
{
	MyColor color;
	color.red = 0.3;
	color.green = 0.3;
	color.blue = 1.0;
	self.objectColor = color;
}

-(void) setRandomFaceColor
{
	MyColor color;
	color.red = (CGFloat) arc4random_uniform(256) / 256;
	color.green = (CGFloat) arc4random_uniform(256) / 256;
	color.blue = (CGFloat) arc4random_uniform(256) / 256;
	self.objectColor = color;
}

- (void) setupFuffr
{
	[self connectToFuffr];
	[self setupGestures1];
	//[self setupTouches]; // For debugging, currently not used.
}

- (void) connectToFuffr
{
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Set active sides.
	[manager
		onFuffrConnected:
		^{
			NSLog(@"Fuffr Connected");
			[[FFRTouchManager sharedManager]
				enableSides: FFRSideTop | FFRSideLeft | FFRSideRight | FFRSideBottom
				touchesPerSide: @2 // Change to 2 touches when using the new parameter case.
				];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"Fuffr Disconnected");
		}];
}

// Log touch events for debugging (not used).

- (void) setupTouches
{
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	[manager
		addTouchObserver: self
		touchBegan: @selector(logTouchBegan:)
		touchMoved: @selector(logTouchMoved:)
		touchEnded: @selector(logTouchEnded:)
		sides: FFRSideRight];
}

- (void) logTouchBegan: (NSSet*)touches
{
	NSLog(@"logTouchBegan: %i", (int)touches.count);
}

- (void) logTouchMoved: (NSSet*)touches
{
	NSArray* touchArray = [touches allObjects];
	FFRTouch* touch = [touchArray objectAtIndex: 0];
	NSLog(@"logTouchMoved: %i %f %f", (int)touches.count,
		touch.location.x, touch.location.y);
}

- (void) logTouchEnded: (NSSet*)touches
{
	NSLog(@"logTouchEnded: %i", (int)touches.count);
}

// Define gesture handlers.

// Comment/uncomment lines [manager addGestureRecognizer: ...
// to add/remove gestures.
- (void) setupGestures1
{
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Remove any existing gestures.
	[manager removeAllGestureRecognizers];

	// Add gestures.

	FFRPanGestureRecognizer* pan = [FFRPanGestureRecognizer new];
	pan.side = FFRSideLeft;
	[pan addTarget: self action: @selector(onPan:)];
	[manager addGestureRecognizer: pan];

	FFRPinchGestureRecognizer* pinch = [FFRPinchGestureRecognizer new];
	pinch.side = FFRSideRight;
	[pinch addTarget: self action: @selector(onPinch:)];
	// Comment out this line to remove pinch from right side.
	[manager addGestureRecognizer: pinch];

	FFRRotationGestureRecognizer* rotation = [FFRRotationGestureRecognizer new];
	rotation.side = FFRSideRight;
	[rotation addTarget: self action: @selector(onRotation:)];
	// Uncomment this line to add rotation to right side.
	[manager addGestureRecognizer: rotation];

	FFRTapGestureRecognizer* tap = [FFRTapGestureRecognizer new];
	tap.side = FFRSideBottom;
	[tap addTarget: self action: @selector(onTapInState1:)];
	[manager addGestureRecognizer: tap];
	
	FFRDoubleTapGestureRecognizer* dtap = [FFRDoubleTapGestureRecognizer new];
	dtap.side = FFRSideRight | FFRSideLeft;
	[dtap addTarget: self action: @selector(onDoubleTap:)];
	[manager addGestureRecognizer: dtap];

	FFRLongPressGestureRecognizer* longPress = [FFRLongPressGestureRecognizer new];
	longPress.side = FFRSideLeft | FFRSideRight;
	[longPress addTarget: self action: @selector(onLongPress:)];
	[manager addGestureRecognizer: longPress];
}

- (void) setupGestures2
{
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Remove any existing gestures.
	[manager removeAllGestureRecognizers];

	// Add gestures.

	FFRPanGestureRecognizer* pan = [FFRPanGestureRecognizer new];
	pan.side = FFRSideLeft;
	[pan addTarget: self action: @selector(onPan:)];
	[manager addGestureRecognizer: pan];

	FFRTapGestureRecognizer* tap = [FFRTapGestureRecognizer new];
	tap.side = FFRSideBottom;
	[tap addTarget: self action: @selector(onTapInState2:)];
	[manager addGestureRecognizer: tap];

	FFRDoubleTapGestureRecognizer* dtap = [FFRDoubleTapGestureRecognizer new];
	dtap.side = FFRSideRight | FFRSideLeft;
	[dtap addTarget: self action: @selector(onDoubleTap:)];
	[manager addGestureRecognizer: dtap];

	FFRLongPressGestureRecognizer* longPress = [FFRLongPressGestureRecognizer new];
	longPress.side = FFRSideLeft | FFRSideRight;
	[longPress addTarget: self action: @selector(onLongPress:)];
	[manager addGestureRecognizer: longPress];

	FFRSwipeGestureRecognizer* swipeLeft = [FFRSwipeGestureRecognizer new];
	swipeLeft.side = FFRSideRight;
	swipeLeft.direction = FFRSwipeGestureRecognizerDirectionLeft;
	[swipeLeft addTarget: self action: @selector(onSwipeLeft:)];
	[manager addGestureRecognizer: swipeLeft];

	FFRSwipeGestureRecognizer* swipeRight = [FFRSwipeGestureRecognizer new];
	swipeRight.side = FFRSideRight;
	swipeRight.direction = FFRSwipeGestureRecognizerDirectionRight;
	[swipeRight addTarget: self action: @selector(onSwipeRight:)];
	[manager addGestureRecognizer: swipeRight];

	FFRSwipeGestureRecognizer* swipeUp = [FFRSwipeGestureRecognizer new];
	swipeUp.side = FFRSideRight;
	swipeUp.direction = FFRSwipeGestureRecognizerDirectionUp;
	[swipeUp addTarget: self action: @selector(onSwipeUp:)];
	[manager addGestureRecognizer: swipeUp];

	FFRSwipeGestureRecognizer* swipeDown = [FFRSwipeGestureRecognizer new];
	swipeDown.side = FFRSideRight;
	swipeDown.direction = FFRSwipeGestureRecognizerDirectionDown;
	[swipeDown addTarget: self action: @selector(onSwipeDown:)];
	[manager addGestureRecognizer: swipeDown];
}

// Gesture handler methods.

-(void) onPan: (FFRPanGestureRecognizer*)gesture
{
	//NSLog(@"onPan: %f %f", gesture.translation.width, gesture.translation.height);

	if (gesture.state == FFRGestureRecognizerStateChanged)
	{
		// Panning is relative to the base translation.
		CGPoint p = self.baseTranslation;

		p.x += (gesture.translation.width * 1.5);
		p.y += gesture.translation.height;

		CGFloat maxTranslationX = self.imageView.bounds.size.width / 2;
		CGFloat maxTranslationY = self.imageView.bounds.size.height / 2;

		p.x = MAX(p.x, -maxTranslationX);
		p.x = MIN(p.x, maxTranslationX);
		p.y = MAX(p.y, -maxTranslationY);
		p.y = MIN(p.y, maxTranslationY);

		self.currentTranslation = p;
	}
	else if (gesture.state == FFRGestureRecognizerStateEnded)
	{
		self.baseTranslation = self.currentTranslation;
	}

	[self redrawImageView];
}

-(void) onPinch: (FFRPinchGestureRecognizer*)gesture
{
	//NSLog(@"onPinch: %f", gesture.scale);

	if (gesture.state == FFRGestureRecognizerStateChanged)
	{
		CGFloat scale = self.baseScale * gesture.scale;
		scale = MIN(scale, 5.0);
		scale = MAX(scale, 0.5);
		self.currentScale = scale;
	}
	else if (gesture.state == FFRGestureRecognizerStateEnded)
	{
		self.baseScale = self.currentScale;
	}

	[self redrawImageView];
}

-(void) onRotation: (FFRRotationGestureRecognizer*)gesture
{
	if (gesture.state == FFRGestureRecognizerStateChanged)
	{
		CGFloat rotation = self.baseRotation - (gesture.rotation * 1.5);

		self.currentRotation = rotation;
	}
	else if (gesture.state == FFRGestureRecognizerStateEnded)
	{
		self.baseRotation = self.currentRotation;
	}

	[self redrawImageView];
}

-(void) onLongPress: (FFRLongPressGestureRecognizer*)gesture
{
	NSLog(@"onLongPress");
	[self initializeRenderingParameters];
	[self redrawImageView];
}

-(void) onDoubleTap: (FFRDoubleTapGestureRecognizer*)gesture
{
	NSLog(@"onDoubleTap");
	
	[self setRandomFaceColor];
	[self redrawImageView];
}

-(void) onTapInState1: (FFRTapGestureRecognizer*)gesture
{
	NSLog(@"onTap1");

	[self setupGestures2];
	[self setFaceColor2];
	[self redrawImageView];
}

-(void) onTapInState2: (FFRTapGestureRecognizer*)gesture
{
	NSLog(@"onTap2");

	[self setupGestures1];
	[self setFaceColor1];
	[self redrawImageView];
}

-(void) onSwipeLeft: (FFRSwipeGestureRecognizer*)gesture
{
	NSLog(@"<<<<<<<<<<<<<<<< onSwipeLeft");

	CGPoint p = self.currentTranslation;
	p.x = -self.imageView.bounds.size.width / 2;
	self.currentTranslation = p;

	[self redrawImageView];
}

-(void) onSwipeRight: (FFRSwipeGestureRecognizer*)gesture
{
	NSLog(@">>>>>>>>>>>>>>>> onSwipeRight");

	CGPoint p = self.currentTranslation;
	p.x = self.imageView.bounds.size.width / 2;
	self.currentTranslation = p;

	[self redrawImageView];
}

-(void) onSwipeUp: (FFRSwipeGestureRecognizer*)gesture
{
	NSLog(@"^^^^^^^^^^^^^^^^ onSwipeUp");

	CGPoint p = self.currentTranslation;
	p.y = -self.imageView.bounds.size.height / 2;
	self.currentTranslation = p;

	[self redrawImageView];
}

-(void) onSwipeDown: (FFRSwipeGestureRecognizer*)gesture
{
	NSLog(@"vvvvvvvvvvvvvvvv onSwipeDown");

	CGPoint p = self.currentTranslation;
	p.y = self.imageView.bounds.size.height / 2;
	self.currentTranslation = p;

	[self redrawImageView];
}

// Drawing the view.

- (void) redrawImageView
{
	// Draw on main thread.
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self drawImageView];
	});
}

- (void) drawImageView
{
	CGFloat centerX = self.imageView.bounds.size.width / 2;
	CGFloat centerY = self.imageView.bounds.size.height / 2;

	// Original unscaled size.
	CGFloat rectSize = 120;

	//UIGraphicsBeginImageContext(self.view.frame.size);
	UIGraphicsBeginImageContext(self.imageView.bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);

	//NSLog(@"drawImage scale: %f", self.objectScale);

	// Translate drawing context.
	CGContextTranslateCTM(
		context,
		centerX + self.currentTranslation.x,
		centerY + self.currentTranslation.y);
	CGContextScaleCTM(
		context,
		self.currentScale,
		self.currentScale);
	CGContextRotateCTM(
		context,
		self.currentRotation);

	// Set drawing color.
	CGContextSetRGBFillColor(
		context,
		self.objectColor.red,
		self.objectColor.green,
		self.objectColor.blue,
		1);

	// Draw centered rect.
	CGContextFillRect(
		context,
		CGRectMake(
			0.0 - (rectSize / 2),
			0.0 - (rectSize / 2),
			rectSize,
			rectSize));

	// Draw mouth and eyes of a face.
	CGContextSetRGBFillColor(context, 0, 0, 0, 1);
	CGContextFillRect(context, CGRectMake(-20, 30, 40, 10)); // Mouth
	CGContextFillRect(context, CGRectMake(-40, -20, 15, 15)); // Left eye
	CGContextFillRect(context, CGRectMake(40-15, -20, 15, 15)); // Right eye

	self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();

	CGContextRestoreGState(context);
	UIGraphicsEndImageContext();
}

@end
