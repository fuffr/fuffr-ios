//
//  AppViewController.m
//  FuffrDots
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "AppViewController.h"

@interface DotColor : NSObject
@property (nonatomic, assign) CGFloat red;
@property (nonatomic, assign) CGFloat green;
@property (nonatomic, assign) CGFloat blue;
@end

@implementation DotColor
@end

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

    self.imageView.backgroundColor = UIColor.whiteColor;

	// Active touches.
	self.touches = [NSMutableSet new];

	// Set up colors for touches. Max touch id should
	// be 20 in the current case implementation (5 touches,
	// 4 sides, touch ids starting at 1).
	self.dotColors = [NSMutableDictionary new];

	[self addColorAtIndex: 1  red: 0.5 green: 0.0 blue: 0.0];
	[self addColorAtIndex: 2  red: 1.0 green: 0.0 blue: 0.0];

	[self addColorAtIndex: 3  red: 0.0 green: 0.5 blue: 0.0];
	[self addColorAtIndex: 4  red: 0.0 green: 1.0 blue: 0.0];

	[self addColorAtIndex: 5  red: 0.0 green: 0.0 blue: 0.5];
	[self addColorAtIndex: 6  red: 0.0 green: 0.0 blue: 1.0];

	[self addColorAtIndex: 7  red: 0.5 green: 0.5 blue: 0.0];
	[self addColorAtIndex: 8  red: 0.5 green: 1.0 blue: 0.0];

	[self addColorAtIndex: 9  red: 1.0 green: 0.5 blue: 0.0];
	[self addColorAtIndex: 10 red: 1.0 green: 1.0 blue: 0.0];

	[self addColorAtIndex: 11 red: 0.5 green: 0.0 blue: 0.5];
	[self addColorAtIndex: 12 red: 0.5 green: 0.0 blue: 1.0];

	[self addColorAtIndex: 13 red: 1.0 green: 0.0 blue: 0.5];
	[self addColorAtIndex: 14 red: 1.0 green: 0.0 blue: 1.0];

	[self addColorAtIndex: 15 red: 0.0 green: 0.5 blue: 0.5];
	[self addColorAtIndex: 16 red: 0.0 green: 0.5 blue: 1.0];

	[self addColorAtIndex: 17 red: 0.0 green: 1.0 blue: 0.5];
	[self addColorAtIndex: 18 red: 0.0 green: 1.0 blue: 1.0];

	[self addColorAtIndex: 19 red: 0.7 green: 0.7 blue: 0.7];
	[self addColorAtIndex: 20 red: 0.3 green: 0.3 blue: 0.3];
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

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

	// Connect to Fuffr and setup touch events.
	[self setupFuffr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupFuffr
{
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Set active sides.
	[manager
		onFuffrConnected:
		^{
			NSLog(@"Fuffr Connected");
			[[FFRTouchManager sharedManager]
				//enableSides: FFRSideTop | FFRSideLeft | FFRSideRight | FFRSideBottom
				enableSides: FFRSideRight | FFRSideLeft
				touchesPerSide: @2 // Change to desired number of touches
				                   // when using the new parameter case.
				];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"Fuffr Disconnected");
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

- (void) fuffrConnected
{
	NSLog(@"fuffrConnected");
}

- (void) touchesBegan: (NSSet*)touches
{
	//NSLog(@"began %i", (int)touches.count);

	for (FFRTouch* touch in touches)
	{
		// A static color table is created in viewDidLoad,
		// replacing commented out code below.
		//DotColor* color = [DotColor new];
		//color.red = (CGFloat) arc4random_uniform(256) / 256;
		//color.green = (CGFloat) arc4random_uniform(256) / 256;
		//color.blue = (CGFloat) arc4random_uniform(256) / 256;
		//[self.dotColors
		//	setObject: color
		//	forKey: [NSNumber numberWithInt: (int)touch.identifier]
		//];

		[self.touches addObject: touch];
	}

	[self redrawView];
}

- (void) touchesMoved: (NSSet*)touches
{
	//NSLog(@"moved %i", (int)touches.count);
	for (FFRTouch* touch in touches)
	{
		//NSLog(@"  id %i", (int)touch.identifier);
	}

	[self redrawView];
}

- (void) touchesEnded: (NSSet*)touches
{
	//NSLog(@"ended %i", (int)touches.count);

	for (FFRTouch* touch in touches)
	{
		[self.touches removeObject: touch];
	}

	[self redrawView];
}

- (void) redrawView
{
	// Draw on main thread.
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self drawImageView];
    });
}

- (void)drawImageView
{
	CGFloat width = self.imageView.bounds.size.width;
	CGFloat height = self.imageView.bounds.size.height;
	CGFloat circleSize = 100;

    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

	for (FFRTouch* touch in self.touches)
	{
		if (touch.phase != UITouchPhaseEnded)
		{
			DotColor* color = [self.dotColors objectForKey:
				[NSNumber numberWithInt: (int)touch.identifier]];
			if (color)
			{
    			CGContextSetRGBFillColor(
					context,
					color.red,
					color.green,
					color.blue,
					1.0);
			}
			else
			{
    			CGContextSetRGBFillColor(
					context,
					0.0,
					0.0,
					0.0,
					1.0);
			}

			CGFloat x = touch.normalizedLocation.x * width;
			CGFloat y = touch.normalizedLocation.y * height;
			CGContextFillEllipseInRect(
				context,
				CGRectMake(
					x - (circleSize / 2),
					y - (circleSize / 2),
					circleSize,
					circleSize));
		}
	}

    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
