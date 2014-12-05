//
//  AppViewController.m
//  FuffrDots
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "AppViewController.h"
#import <CoreText/CTLine.h>
#import <CoreText/CTFont.h>
#import <CoreText/CTStringAttributes.h>

@implementation AppViewController

dispatch_semaphore_t frameRenderingSemaphore;
dispatch_queue_t openGLESContextQueue;

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

	// Create a GL view for drawing.
	self.glView = [[EAGLView alloc] initWithFrame:self.view.bounds];
	self.glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.glView.userInteractionEnabled = YES;
    self.glView.backgroundColor = [UIColor colorWithRed:48/255.0 green:48/255.0 blue:48/255.0 alpha:1];
	
	[self.view addSubview:self.glView];

	frameRenderingSemaphore = dispatch_semaphore_create(1);
	openGLESContextQueue = dispatch_get_main_queue();

	// Create view that displays messages.
	[self createMessageView];

	// Create button and popup menu for settings.
	[self createSettingsButtonAndPopUp];

	// Active touches.
	self.touches = [NSMutableSet new];

	// When paintmode is on touches are painted on the screen.
	// When off dots are displayed.
	self.paintModeOn = NO;

	// Create colors for the dots.
	[self createColors];
}

-(void) addColorAtIndex: (int)index
	red: (CGFloat)red
	green: (CGFloat)green
	blue: (CGFloat)blue
{
	DotColor* color = [DotColor new];
	color.red = red;
	color.green = green;
	color.blue = blue;
	[self.dotColors
		setObject: color
		forKey: [NSNumber numberWithInt: index]
	];
}

-(void) createMessageView
{
	self.messageView = [[UILabel alloc] initWithFrame: CGRectMake(10, 25, 300, 300)];
    self.messageView.textColor = [UIColor blackColor];
    self.messageView.backgroundColor = [UIColor clearColor];
    self.messageView.userInteractionEnabled = NO;
	//self.messageView.autoresizingMask = UIViewAutoresizingNone;
	self.messageView.lineBreakMode = NSLineBreakByWordWrapping;
	self.messageView.numberOfLines = 0;
    self.messageView.text = @"";
    self.messageView.textColor = [UIColor whiteColor];
    [self.view addSubview: self.messageView];
}

-(void) createSettingsButtonAndPopUp
{
	// Create settings button.
	CGRect bounds = CGRectMake(self.view.bounds.size.width - 90, 22, 90, 25);
	self.buttonSettings = [UIButton buttonWithType: UIButtonTypeSystem];
    [self.buttonSettings setFrame: bounds];
	[self.buttonSettings setTitle: @"Settings" forState: UIControlStateNormal];
    [self.buttonSettings setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.buttonSettings
		addTarget: self
		action: @selector(onButtonSettings:)
		forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: self.buttonSettings];

	// Create popup menu.
	self.actionSheet =
		[[UIActionSheet alloc]
			initWithTitle: nil
			delegate: self
			cancelButtonTitle:@"Cancel"
			destructiveButtonTitle:nil
			otherButtonTitles: @"Dots", @"Paint", nil];
}

- (void) createColors
{
    CGFloat redBaseColor, greenBaseColor, blueBaseColor, redColor, blueColor, greenColor;
	// Set up colors for touches. Max touch id should
	// be 20 in the current case implementation (5 touches,
	// 4 sides, touch ids starting at 1).
	self.dotColors = [NSMutableDictionary new];
    
    // Yellow
    redBaseColor = 248;
    greenBaseColor = 231;
    blueBaseColor = 28;
    redColor = redBaseColor;
    greenColor = greenBaseColor;
    blueColor = blueBaseColor;
    
    for (int i = 1; i < 6; i++)
    {
        [self addColorAtIndex:i red:redColor/255.0 green:greenColor/255.0 blue:blueColor/255.0];
        redColor = redBaseColor - (redBaseColor * (0.15*i));
        greenColor = greenBaseColor - (greenBaseColor * (0.15*i));
        blueColor = blueBaseColor - (blueBaseColor * (0.15*i));
    }
    
    // Blue
    redBaseColor = 33;
    greenBaseColor = 115;
    blueBaseColor = 188;
    redColor = redBaseColor;
    greenColor = greenBaseColor;
    blueColor = blueBaseColor;
    
    for (int i = 6; i < 11; i++)
    {
        [self addColorAtIndex:i red:redColor/255.0 green:greenColor/255.0 blue:blueColor/255.0];
        redColor = redBaseColor - (redBaseColor * (0.15*(i-5)));
        greenColor = greenBaseColor - (greenBaseColor * (0.15*(i-5)));
        blueColor = blueBaseColor - (blueBaseColor * (0.15*(i-5)));
    }
    
    // Green
    redBaseColor = 122;
    greenBaseColor = 207;
    blueBaseColor = 66;
    redColor = redBaseColor;
    greenColor = greenBaseColor;
    blueColor = blueBaseColor;
    
    for (int i = 11; i < 16; i++)
    {
        [self addColorAtIndex:i red:redColor/255.0 green:greenColor/255.0 blue:blueColor/255.0];
        redColor = redBaseColor - (redBaseColor * (0.15*(i-10)));
        greenColor = greenBaseColor - (greenBaseColor * (0.15*(i-10)));
        blueColor = blueBaseColor - (blueBaseColor * (0.15*(i-10)));
    }
    
    // Red
    redBaseColor = 238;
    greenBaseColor = 74;
    blueBaseColor = 45;
    redColor = redBaseColor;
    greenColor = greenBaseColor;
    blueColor = blueBaseColor;
    
    for (int i = 16; i < 21; i++)
    {
        [self addColorAtIndex:i red:redColor/255.0 green:greenColor/255.0 blue:blueColor/255.0];
        redColor = redBaseColor - (redBaseColor * (0.15*(i-15)));
        greenColor = greenBaseColor - (greenBaseColor * (0.15*(i-15)));
        blueColor = blueBaseColor - (blueBaseColor * (0.15*(i-15)));
    }
}

-(void) showMessage:(NSString*)message
{
	self.messageView.text = message;
	self.messageView.frame = CGRectMake(10, 25, 300, 300);
	[self.messageView sizeToFit];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

	// Track orientation changes.
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(orientationChanged:)
		name: UIDeviceOrientationDidChangeNotification
		object:nil];

	// Connect to Fuffr and setup touch events.
	[self setupFuffr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) onButtonSettings: (id)sender
{
	[self.actionSheet
		showFromRect: self.buttonSettings.frame
		inView: self.view
		animated: YES];
}

- (void) actionSheet: (UIActionSheet *)actionSheet
	clickedButtonAtIndex: (NSInteger)buttonIndex
{
	if (1 == buttonIndex) { self.paintModeOn = YES; }
	else { self.paintModeOn = NO; }
}

- (void) setupFuffr
{
	[self showMessage: @"Scanning for Fuffr..."];

	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	[manager
		onFuffrConnected:
		^{
			NSLog(@"Fuffr Connected");
			[self showMessage: @"Fuffr Connected"];
			[manager useSensorService:
			^{
				// Sensor is available, set active sides.
				[[FFRTouchManager sharedManager]
					enableSides: FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom
					touchesPerSide: @5];
			}];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"Fuffr Disconnected");
			[self showMessage: @"Fuffr Disconnected"];
		}];

	// Register methods for touch events. Here the side constants are
	// bit-or:ed to capture touches on all four sides.
	[manager
		addTouchObserver: self
		touchBegan: @selector(touchesBegan:)
		touchMoved: @selector(touchesMoved:)
		touchEnded: @selector(touchesEnded:)
		sides: FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom];
}

- (void) touchesBegan: (NSSet*)touches
{
	//NSLog(@"@@@ touchesBegan: %i", (int)touches.count);

	for (FFRTouch* touch in touches)
	{
		[self.touches addObject: touch];
	}

	[self redrawView];
}

- (void) touchesMoved: (NSSet*)touches
{
	//NSLog(@"@@@ touchesMoved: %i", (int)touches.count);

	[self redrawView];
}

- (void) touchesEnded: (NSSet*)touches
{
	//NSLog(@"@@@ touchesEnded: %i", (int)touches.count);

	for (FFRTouch* touch in touches)
	{
		[self.touches removeObject: touch];
	}

	[self redrawView];
}

- (void) orientationChanged: (NSNotification *)notification
{
	[self redrawView];
}

- (void) redrawView
{
	// Update touch count messge.
	NSString* message = [NSString
		stringWithFormat: @"Number of touches: %i FPS: %i",
		(int)self.touches.count,
		self.glView.framesPerSecond];
	[self showMessage: message];

	// Render asynchronously, only one frame at a time.
	if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
	{
		return;
	}
	
	dispatch_async(openGLESContextQueue, ^{
		[self drawImageView];
		dispatch_semaphore_signal(frameRenderingSemaphore);
	});
}

- (void)drawImageView
{
	if (self.paintModeOn)
	{
		self.glView.clearsContextBeforeDrawing = NO;
	}

	// Copying set to prevent exception:
	//   *** Terminating app due to uncaught exception 'NSGenericException',
	//   reason: '*** Collection <__NSSetM: 0x178054460> was mutated while
	//   being enumerated.'
	// from occuring in EAGLView in method drawViewWithTouches in the for-loop.
	[self.glView
		drawViewWithTouches:[NSSet setWithSet:self.touches]
		paintMode:self.paintModeOn
		dotColors:self.dotColors];
}

@end
