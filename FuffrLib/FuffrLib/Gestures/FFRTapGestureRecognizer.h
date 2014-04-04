//
//  FFRTapGestureRecognizer.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-31.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRGestureRecognizer.h"


/**
 A tap gesture recognizer
 */
@interface FFRTapGestureRecognizer : FFRGestureRecognizer
{
    NSTimeInterval _start;
    CGPoint _startPoint;
}


@end
