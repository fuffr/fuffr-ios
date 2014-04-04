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

	// Set background color.
    self.imageView.backgroundColor = UIColor.whiteColor;

	self.dotColors = [NSMutableDictionary new];
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

	// Connect to Fuffr, the onSuccess method will be
	// called when connection is established.
	// Support for onError is not complete.
	[manager
		connectToFuffrNotifying: self
		onSuccess: @selector(fuffrConnected)
		onError: nil];

	// Register methods for touch events. Here the side constants are
	// bit-or:ed to capture touches on all four sides.
	[manager
		addTouchObserver: self
		touchBegan: @selector(drawTouchesBegan:)
		touchMoved: @selector(drawTouches:)
		touchEnded: @selector(drawTouches:)
		side: FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom];

}

- (void) fuffrConnected
{
	NSLog(@"fuffrConnected");
}

- (void) drawTouchesBegan: (NSSet*)touches
{
	for (FFRTouch* touch in touches)
	{
		if (nil == [self.dotColors objectForKey:
				//[NSValue valueWithPointer: (__bridge const void *)(touch)]
				[NSNumber numberWithInt: (int)touch.identifier]
				])
		{
			DotColor* color = [DotColor new];
			color.red = (CGFloat) arc4random_uniform(256) / 256;
			color.green = (CGFloat) arc4random_uniform(256) / 256;
			color.blue = (CGFloat) arc4random_uniform(256) / 256;
			[self.dotColors
				setObject: color
				forKey:
					//[NSValue valueWithPointer: (__bridge const void *)(touch)]
					[NSNumber numberWithInt: (int)touch.identifier]
			];
		}
	}

	// Draw on main thread.
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self drawImageView: touches];
    });
}

- (void) drawTouches: (NSSet*)touches
{
	// Draw on main thread.
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self drawImageView: touches];
    });
}

- (void)drawImageView: (NSSet*)touches
{
	CGFloat width = self.imageView.bounds.size.width;
	CGFloat height = self.imageView.bounds.size.height;
	CGFloat circleSize = 100;

    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

	for (FFRTouch* touch in touches)
	{
		if (touch.phase != UITouchPhaseEnded)
		{
			DotColor* color = [self.dotColors objectForKey:
				[NSNumber numberWithInt: (int)touch.identifier]
				//[NSValue valueWithPointer: (__bridge const void *)(touch)]
				];
    		CGContextSetRGBFillColor(context, color.red, color.green, color.blue, 1.0);

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
