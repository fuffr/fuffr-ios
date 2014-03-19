//
//  NnSensorTagDemo.h
//  SensorCaseDemo
//
//  Created by Christoffer Sjöberg on 2013-10-25.
//  Copyright (c) 2013 Neonode. All rights reserved.
//

#import "FFRBLEManager.h"

@interface NnSensorTagDemo : FFRBLEManager {
    CGSize _simulatedField;
    CGPoint _reportedShift;
    CGPoint _currentShift;
}


@property (nonatomic, assign) CGPoint ballLocation;

-(void) setSimulatedField:(CGSize)size;

@end
