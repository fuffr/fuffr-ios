//
//  FFRFirmwareMetaData.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-13.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRFirmwareMetaData.h"

@implementation FFRFirmwareMetaData


+(FFRFirmwareMetaData*) metaDataFromFile:(NSString*)fullPathAndFilename {
    FFRFirmwareMetaData* data = [[FFRFirmwareMetaData alloc] initWithFileName:fullPathAndFilename];
    return data;
}

-(id) initWithFileName:(NSString *)fullPathAndFilename {
    if (self = [super init]) {
        self.pathAndFilename = fullPathAndFilename;

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, TRUE);
        NSString *publicDocumentsDir = [paths objectAtIndex:0];
        self.bundled = [fullPathAndFilename rangeOfString:publicDocumentsDir].location == NSNotFound;

        NSError* error;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPathAndFilename error:&error];

        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        self.filesize = [fileSizeNumber intValue];

        self.modifiedDate = [fileAttributes objectForKey:NSFileModificationDate];
        self.filename = [[fullPathAndFilename lastPathComponent] stringByDeletingPathExtension];
    }

    return self;
}

@end
