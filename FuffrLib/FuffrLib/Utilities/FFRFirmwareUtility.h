//
//  FFRUtility.h
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-13.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFRFirmwareUtility : NSObject


+(NSArray*) firmwareFilesInDocuments;
+(NSArray*) firmwareFilesInBundle;
+(NSArray*) firmwareFiles;
+(NSString*) writeFirmwareToDocuments:(NSData*)firmwareData;

@end
