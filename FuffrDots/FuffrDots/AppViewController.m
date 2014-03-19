//
//  AppViewController.m
//  FuffrDots
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "AppViewController.h"

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
		touchBegan: @selector(drawTouches:)
		touchMoved: @selector(drawTouches:)
		touchEnded: @selector(drawTouches:)
		side: FFRSideLeft | FFRSideRight | FFRSideTop | FFRSideBottom];

}

- (void) fuffrConnected
{
	NSLog(@"fuffrConnected");
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
		CGFloat x = touch.normalizedLocation.x * width;
		CGFloat y = touch.normalizedLocation.y * height;
    	CGContextSetRGBFillColor(context, 0.2, 0.749, 0.871, 1);
		CGContextFillEllipseInRect(
			context,
			CGRectMake(
				x - (circleSize / 2),
				y - (circleSize / 2),
				circleSize,
				circleSize));
	}

    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
