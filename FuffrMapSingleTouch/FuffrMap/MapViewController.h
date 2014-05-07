//
//  MapViewController.h
//  FuffrMap
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <FuffrLib/FFRTouchManager.h>
#import "LowPassFilter.h"

@interface MapViewController : UIViewController <MKMapViewDelegate>

// The map view.
@property MKMapView* mapView;

// Current map altitude
@property CLLocationDistance mapAltitude;

// Properties for the panning touch handler.
@property (nonatomic, weak) FFRTouch* panningTouch;
@property LowPassFilter* panningFilterX;
@property LowPassFilter* panningFilterY;

// Properties for the zooming touch handler.
@property (nonatomic, weak) FFRTouch* zoomingTouch;
@property LowPassFilter* zoomingFilterY;

@end
