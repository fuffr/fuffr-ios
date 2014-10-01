//
//  AppViewController.m
//  Implementation file for the FuffrHello view controller.
//
//  Created by Fuffr on 16/03/14.
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

	// Create view that displays messages.
	[self createMessageView];

	// Set circle size and initial coordinates.
	CGFloat width = self.imageView.bounds.size.width;
	CGFloat height = self.imageView.bounds.size.height;
	self.circleSize = 100;
	self.circleRightX = width / 2;
	self.circleRightY = height / 4 * 1;
	self.circleLeftX = width / 2;
	self.circleLeftY = height / 4 * 3;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

	// Draw the initial view.
	[self drawImageView];

	// Connect to Fuffr and setup touch events.
	[self setupFuffr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
    [self.view addSubview: self.messageView];
}

-(void) showMessage:(NSString*)message
{
	self.messageView.text = message;
	self.messageView.frame = CGRectMake(10, 25, 300, 300);
	[self.messageView sizeToFit];
}

- (void)drawImageView
{
    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw right circle.
    CGContextSetRGBFillColor(context, 0.2, 0.749, 0.871, 1);
	CGContextFillEllipseInRect(
		context,
		CGRectMake(
			self.circleRightX - (self.circleSize / 2),
			self.circleRightY - (self.circleSize / 2),
			self.circleSize,
			self.circleSize));

	// Draw left circle.
    CGContextSetRGBFillColor(context, 0.769, 0.302, 0.722, 1);
	CGContextFillEllipseInRect(
		context,
		CGRectMake(
			self.circleLeftX - (self.circleSize / 2),
			self.circleLeftY - (self.circleSize / 2),
			self.circleSize,
			self.circleSize));

    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void) setupFuffr
{
	[self showMessage: @"Scanning for Fuffr..."];

	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Set active sides.
	[manager
		onFuffrConnected:
		^{
			[manager useSensorService:
			^{
				NSLog(@"Fuffr Connected");
				[self showMessage: @"Fuffr Connected"];
				[[FFRTouchManager sharedManager]
					enableSides: FFRSideLeft | FFRSideRight
					touchesPerSide: @1
					];
			}];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"Fuffr Disconnected");
			[self showMessage: @"Fuffr Disconnected"];
		}];

	// Register methods for right side touches. The touchEnded
	// method is not used in this example.
	[manager
		addTouchObserver: self
		touchBegan: @selector(touchRightBegan:)
		touchMoved: @selector(touchRightMoved:)
		touchEnded: nil
		sides: FFRSideRight];

	// Register methods for left side touches. The touchEnded
	// method is not used in this example.
	[manager
		addTouchObserver: self
		touchBegan: @selector(touchLeftBegan:)
		touchMoved: @selector(touchLeftMoved:)
		touchEnded: nil
		sides: FFRSideLeft];
}

- (void) touchRightBegan: (NSSet*)touches
{
	// In this example we only use one touch object for
	// each left/right side. Here the reference to the
	// first right side touch is saved.
	self.touchRight = [[touches allObjects] firstObject];

	// Set position of the right circle and redraw.
	[self moveRightCircle: self.touchRight.normalizedLocation];
}

- (void) touchLeftBegan: (NSSet*)touches
{
	// In this example we only use one touch object for
	// each left/right side. Here the reference to the
	// first left side touch is saved.
	self.touchLeft = [[touches allObjects] firstObject];

	// Set position of the left circle and redraw.
	[self moveLeftCircle: self.touchLeft.normalizedLocation];
}

- (void) touchRightMoved: (NSSet*)touches
{
	// Check that tracked touch is present in current set.
	if (![touches containsObject: self.touchRight])
	{
		return;
	}

	// Set position of the right circle and redraw. Note that
	// rather than using the set of touches, we use the touch
	// that we got from the touch began event.
	[self moveRightCircle: self.touchRight.normalizedLocation];
}

- (void) touchLeftMoved: (NSSet*)touches
{
	// Check that tracked touch is present in current set.
	if (![touches containsObject: self.touchLeft])
	{
		return;
	}

	// Set position of the left circle and redraw. Note that
	// rather than using the set of touches, we use the touch
	// that we got from the touch began event.
	[self moveLeftCircle: self.touchLeft.normalizedLocation];
}

- (void) moveRightCircle: (CGPoint)normalizedLocation
{
	// Set circle position and draw on main thread.
	CGFloat width = self.imageView.bounds.size.width;
	CGFloat height = self.imageView.bounds.size.height;
	self.circleRightX = normalizedLocation.x * width;
	self.circleRightY = normalizedLocation.y * height;
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self drawImageView];
    });
}

- (void) moveLeftCircle: (CGPoint)normalizedLocation
{
	// Set circle position and draw on main thread.
	CGFloat width = self.imageView.bounds.size.width;
	CGFloat height = self.imageView.bounds.size.height;
	self.circleLeftX = normalizedLocation.x * width;
	self.circleLeftY = normalizedLocation.y * height;
	dispatch_async(dispatch_get_main_queue(),
	^{
		[self drawImageView];
    });
}

@end
