//
//  FFRFirmwareMetaData.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-13.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFRFirmwareMetaData : NSObject

+(FFRFirmwareMetaData*) metaDataFromFile:(NSString*)fullPathAndFilename;
-(id) initWithFileName:(NSString*)fullPathAndFilename;

@property (nonatomic, copy) NSString* filename;
@property (nonatomic, copy) NSString* pathAndFilename;
@property (nonatomic, assign) BOOL bundled;
@property (nonatomic, assign) NSUInteger filesize;
@property (nonatomic, copy) NSDate* modifiedDate;

@end
