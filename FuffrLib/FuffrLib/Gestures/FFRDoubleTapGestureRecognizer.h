//
//  FFRDoubleTapGestureRecognizer.h
//  FuffrLib
//
//  Created by Mac Builder on 4/23/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRGestureRecognizer.h"

@interface FFRDoubleTapGestureRecognizer : FFRGestureRecognizer
{
    NSTimeInterval _startTime;
    CGPoint _startPoint;
    uint _count;
    bool _down;
}

@end
