//
//  FFRQuadrantSpaceMapper.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRCaseHandler.h"


/**
 Converts touches from all sensors to equal parts of the screen (screen is split in 4 quadrants)
 */
@interface FFRQuadrantSpaceMapper : NSObject<FFRExternalSpaceMapper>

@end
