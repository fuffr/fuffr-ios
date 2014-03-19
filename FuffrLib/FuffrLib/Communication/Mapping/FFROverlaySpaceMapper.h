//
//  FFROverlaySpaceMapper.h
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-18.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRCaseHandler.h"


/**
 Converts touches from all sensors to the full extents of the screen, effectively overlaying all touches
 */
@interface FFROverlaySpaceMapper : NSObject<FFRExternalSpaceMapper>

@end
