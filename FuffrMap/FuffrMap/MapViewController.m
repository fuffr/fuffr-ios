//
//  MapViewController.m
//  FuffrMap
//
//  Created by miki on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "MapViewController.h"
#import <FuffrLib/UIView+Toast.h>

@interface MapViewController ()

// Current map altitude
@property CLLocationDistance mapAltitude;

// Origin for panning gesture.
@property CLLocationCoordinate2D panningOrigin;

// Origin for zooming (pinch) gesture.
@property CLLocationDistance zoomingOrigin;

// Origin for rotattion gesture.
@property CLLocationDirection rotationOrigin;

@end

@implementation MapViewController

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
	self.mapView = [[MKMapView alloc] initWithFrame: self.view.bounds];
    self.mapView.userInteractionEnabled = YES;
    [self.view addSubview: self.mapView];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];

	// Set/save map properties.
	self.mapAltitude = self.mapView.camera.altitude;
	CLLocationCoordinate2D center = self.mapView.centerCoordinate;
	center.longitude -= 1.0;
	//center.latitude = 89;
    [self.mapView setCenterCoordinate:center animated:false];

	// Connect to Fuffr and setup touch events.
	[self setupFuffr];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setupFuffr
{
	[self.view makeToast: @"Scanning for Fuffr"];

	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Set active sides.
	[manager
		onFuffrConnected:
		^{
			NSLog(@"Fuffr Connected");

			[self.view makeToast: @"Fuffr Connected"];

			[[FFRTouchManager sharedManager]
				enableSides: FFRSideLeft | FFRSideRight
				touchesPerSide: @2
				];
		}
		onFuffrDisconnected:
		^{
			NSLog(@"Fuffr Disconnected");

			[self.view makeToast: @"Fuffr Disconnected"];
		}];

	// Register gesture listeners.

	FFRPanGestureRecognizer* pan = [FFRPanGestureRecognizer new];
	pan.side = FFRSideRight;
	[pan addTarget: self action: @selector(onPan:)];
	[manager addGestureRecognizer: pan];

	FFRPinchGestureRecognizer* pinch = [FFRPinchGestureRecognizer new];
	pinch.side = FFRSideLeft;
	[pinch addTarget: self action: @selector(onPinch:)];
	[manager addGestureRecognizer: pinch];

	FFRRotationGestureRecognizer* rotation = [FFRRotationGestureRecognizer new];
	rotation.side = FFRSideLeft;
	[rotation addTarget: self action: @selector(onRotation:)];
	[manager addGestureRecognizer: rotation];
}

- (void) fuffrConnected
{
	NSLog(@"fuffrConnected");
}

- (void) onPan: (FFRPanGestureRecognizer*)gesture
{
	if (FFRGestureRecognizerStateBegan == gesture.state)
	{
		// Set translation origin.
		self.panningOrigin = self.mapView.centerCoordinate;
	}
	else
	if (FFRGestureRecognizerStateChanged == gesture.state)
	{
		// Panning speed is dependent on the altitude (less speed on lower altitude).
		CLLocationDistance altitude = self.mapView.camera.altitude;
		CGFloat panningSpeed = altitude * 0.000000015;

		// Update center position. Horizontal panning is made faster
		// because the app displays in portrait mode.
		CLLocationCoordinate2D center = self.mapView.centerCoordinate;
		center.longitude =
			self.panningOrigin.longitude -
			(gesture.translation.width * panningSpeed * 2.0);
		center.latitude =
			self.panningOrigin.latitude +
			(gesture.translation.height * panningSpeed);

		// Limit latitude and wrap longitude.
		if (center.longitude > 179.0) { center.longitude = -179.0; }
		if (center.longitude < -179.0) { center.longitude = 179.0; }
		if (center.latitude > 89.0) { center.latitude = 89.0; }
		if (center.latitude < -89.0) { center.latitude = -89.0; }

		// Set the center position of the map view on the main thread.
		dispatch_async(dispatch_get_main_queue(),
		^{
			self.mapView.camera.centerCoordinate = center;
			self.mapView.camera.altitude = self.mapAltitude;
		});
	}
}

- (void) onPinch: (FFRPinchGestureRecognizer*)gesture
{
	//NSLog(@"onPinch: scale: %f", gesture.scale);

	if (FFRGestureRecognizerStateBegan == gesture.state)
	{
		// Set zooming origin.
		self.zoomingOrigin = self.mapView.camera.altitude;
	}
	else
	if (FFRGestureRecognizerStateChanged == gesture.state)
	{
		// The zoom step is dependent on the altitude.
		// Lower altitude means smaller zoom step,
		// higher altitude bigger zoom step.
		CLLocationDistance altitude =
			self.zoomingOrigin +
			(((1.0 / gesture.scale) * self.zoomingOrigin) - self.zoomingOrigin);

		// Handle max/min values for the altitude.
		if (altitude > 32000000.0) { altitude = 32000000.0; }
		if (altitude < 200.0) { altitude = 200.0; }

		// Save altitude.
		self.mapAltitude = altitude;

		// Set altitude on main thread.
		dispatch_async(dispatch_get_main_queue(),
		^{
			self.mapView.camera.altitude = altitude;
		});
	}
}

- (void) onRotation: (FFRRotationGestureRecognizer*)gesture
{
	//NSLog(@"onRotation: rotation: %f", gesture.rotation);
	
	if (FFRGestureRecognizerStateBegan == gesture.state)
	{
		// Set rotation origin.
		self.rotationOrigin = self.mapView.camera.heading;
	}
	else
	if (FFRGestureRecognizerStateChanged == gesture.state)
	{
		CGFloat degrees = gesture.rotation * (180 / M_PI);
		if (ABS(degrees) > 15)
		{
			CLLocationDirection heading = self.rotationOrigin + degrees;

			// Set heading on main thread.
			dispatch_async(dispatch_get_main_queue(),
			^{
				self.mapView.camera.heading = heading;
			});
		}
	}
}

@end
