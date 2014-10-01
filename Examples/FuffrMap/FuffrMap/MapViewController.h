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

@interface MapViewController : UIViewController <MKMapViewDelegate>

// The map view.
@property MKMapView* mapView;

@end
