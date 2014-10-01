//
//  FFRLowPassFilter.m
//  FuffrLib
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRLowPassFilter.h"

@implementation FFRLowPassFilter

- (FFRLowPassFilter*) init
{
	self.cutOff = 0.80;
	self.state = 0.0;
	return self;
}

- (CGFloat) filter: (CGFloat) value
{
	self.state =
		(value * (1.0 - self.cutOff))
		+ (self.state * self.cutOff);
	return self.state;
}

@end
