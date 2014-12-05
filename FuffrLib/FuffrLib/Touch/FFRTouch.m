//
//  FFRTouch.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRTouch.h"


@implementation FFRTouch


@synthesize timestamp = _timestamp;
@synthesize phase = _phase;
@synthesize location = _location;
@synthesize previousLocation = _previousLocation;
@synthesize identifier = _identifier;

-(id) init {
	if (self = [super init]) {
		// Initial state.
		self.phase = FFRTouchPhaseEnded;

		// Time stamp is set elsewhere.
		//self.timestamp = [[NSProcessInfo processInfo] systemUptime];
	}

	return self;
}

-(void) setLocation:(CGPoint)location {
	if (location.x != self.location.x || location.y != self.location.y) {
		_previousLocation = self.location;
		_location = location;
	}
}

-(void) setTimestamp:(NSTimeInterval)timestamp {
	_timestamp = timestamp;
}

-(NSTimeInterval) timestamp {
	return _timestamp;
}

@end
