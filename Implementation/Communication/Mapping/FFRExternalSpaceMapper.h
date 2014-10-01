//
//  FFRExternalSpaceMapper.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-28.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#ifndef FFRExternalSpaceMapper_h
#define FFRExternalSpaceMapper_h

/**
 Converts raw touch data from the side of the case to screen coordinates
 */
@protocol FFRExternalSpaceMapper <NSObject>

/**
 Converts a normalized coordinate 0..1, 0..1 to screen space
 */
-(CGPoint) locationOnScreen:(CGPoint) point fromSide:(FFRSide)side;

@end

#endif
