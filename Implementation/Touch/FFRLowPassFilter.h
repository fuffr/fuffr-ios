//
//  FFRLowPassFilter.h
//  FuffrLib
//
//  Created by Fuffr on 18/03/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A low-pass filter intended to smooth out noisy touch data.
 */
@interface FFRLowPassFilter : NSObject

// The cutoff for the filter must be a value between 0 and 1,
// where 0 means no filtering (everything is passed through)
// and 1 that no signal is passed through.
@property CGFloat cutOff;
@property CGFloat state;

// Sets the cutoff to a default value.
- (FFRLowPassFilter*) init;

// Takes a value as input and returns the filtered value.
- (CGFloat) filter: (CGFloat) value;

@end
