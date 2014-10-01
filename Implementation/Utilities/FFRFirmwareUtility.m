//
//  FFRUtility.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-13.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRFirmwareUtility.h"

@implementation FFRFirmwareUtility


+(NSArray*) firmwareFiles {
    NSMutableArray *fwFiles = [NSMutableArray arrayWithArray:[self firmwareFilesInBundle]];
    [fwFiles addObjectsFromArray:[self firmwareFilesInDocuments]];

    return fwFiles;
}

+(NSArray*) firmwareFilesInDocuments {
    NSMutableArray *fwFiles = [NSMutableArray array];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, TRUE);
    NSString *publicDocumentsDir = [paths objectAtIndex:0];

    NSError *error;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:publicDocumentsDir error:&error];

    if (files == nil || error) {
        NSLog(@"Could not find any firmware files in documents.");
        return fwFiles;
    }
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"bin" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSString *fullPath = [publicDocumentsDir stringByAppendingPathComponent:file];
            [fwFiles addObject:fullPath];
        }
    }
    
    return fwFiles;
}

+(NSArray*) firmwareFilesInBundle {
    NSMutableArray *fwFiles = [NSMutableArray array];

    NSString* path = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"/firmware/"];

    NSError* error;
    NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];

    if (files == nil || error) {
        NSLog(@"Could not find any firmware files in bundle.");
        return fwFiles;
    }
    for (NSString *file in files) {
        if ([file.pathExtension compare:@"bin" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            NSString *fullPath = [path stringByAppendingPathComponent:file];
            [fwFiles addObject:fullPath];
        }
    }

    return fwFiles;
}

+(NSString*) writeFirmwareToDocuments:(NSData*)data {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, TRUE);
    NSString *path = [paths objectAtIndex:0];

    NSString* fullPath = [path stringByAppendingPathComponent:@"/downloadedFirmware.bin"];
    [data writeToFile:fullPath atomically:TRUE];

    return fullPath;
}

@end
