//
//  MapViewController.m
//  FuffrMap
//
//  Created by miki on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "MapViewController.h"

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

	// Init instance variables.
	self.panningFilterX = [LowPassFilter new];
	self.panningFilterY = [LowPassFilter new];
	self.zoomingFilterY = [LowPassFilter new];
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
	// Get a reference to the touch manager.
	FFRTouchManager* manager = [FFRTouchManager sharedManager];

	// Connect to the case.
	[manager
		connectToFuffrNotifying: self
		onSuccess: @selector(fuffrConnected)
		onError: nil];

	// Register panning touch methods.
	[manager
		addTouchObserver: self
		touchBegan: @selector(panningTouchBegan:)
		touchMoved: @selector(panningTouchMoved:)
		touchEnded: nil
		side: FFRSideRight];

	// Register zooming touch methods.
	[manager
		addTouchObserver: self
		touchBegan: @selector(zoomingTouchBegan:)
		touchMoved: @selector(zoomingTouchMoved:)
		touchEnded: nil
		side: FFRSideLeft];
}

- (void) fuffrConnected
{
	NSLog(@"fuffrConnected");
}

- (void) panningTouchBegan: (NSSet*)touches
{
	self.panningTouch = [[touches allObjects] firstObject];
}

- (void) panningTouchMoved: (NSSet*)touches
{
	// Check that tracked touch is present in current set.
	if (![touches containsObject: self.panningTouch])
	{
		return;
	}

	// Calculate the panning distance.
	CGFloat deltaX = [self.panningFilterX filter:
		self.panningTouch.location.x - self.panningTouch.previousLocation.x];
	CGFloat deltaY = [self.panningFilterY filter:
		self.panningTouch.location.y - self.panningTouch.previousLocation.y];

	// Panning speed is dependent on the altitude (less speed on lower altitude).
	CLLocationDistance altitude = self.mapView.camera.altitude;
	CGFloat panningSpeed = altitude * 0.00000002;

	// Update center position. Horizontal panning is made faster
	// because the app displays in portrait mode.
	CLLocationCoordinate2D center = self.mapView.centerCoordinate;
	center.longitude -= (deltaX * panningSpeed * 3.0);
	center.latitude += (deltaY * panningSpeed);

	// Limit latitude and wrap longitude.
	if (center.longitude > 179.0) { center.longitude = -179.0; }
	if (center.longitude < -179.0) { center.longitude = 179.0; }
	if (center.latitude > 89.0) { center.latitude = 89.0; }
	if (center.latitude < -89.0) { center.latitude = -89.0; }

	// Set the center position of the map view in the main thread.
	dispatch_async(dispatch_get_main_queue(),
	^{
		self.mapView.camera.centerCoordinate = center;
		self.mapView.camera.altitude = self.mapAltitude;
    });
}

- (void) zoomingTouchBegan: (NSSet*)touches
{
	self.zoomingTouch = [[touches allObjects] firstObject];
}

- (void) zoomingTouchMoved: (NSSet*)touches
{
	// Check that tracked touch is present in current set.
	if (![touches containsObject: self.zoomingTouch])
	{
		return;
	}

	// The zoomstep is dependent on the altitude.
	// Lower altitude means smaller zoom step,
	// higher altitude bigger zoom step.
	CLLocationDistance deltaY = [self.zoomingFilterY filter:
		self.zoomingTouch.location.y - self.zoomingTouch.previousLocation.y];
	CLLocationDistance altitude = self.mapView.camera.altitude;
	CLLocationDistance zoomingSpeed = altitude * 0.0075;
	altitude += (deltaY * zoomingSpeed);

	// Handle max/min values for the altitude.
	if (altitude > 32000000.0) { altitude = 32000000.0; }
	if (altitude < 200.0) { altitude = 200.0; }

	// Save altitude.
	self.mapAltitude = altitude;

	// Set altitude in main thread.
	dispatch_async(dispatch_get_main_queue(),
	^{
		self.mapView.camera.altitude = altitude;
    });
}

@end
