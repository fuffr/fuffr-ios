//
//  FFRFirmwareDownloader.m
//  FuffrLib
//
//  Created by miki on 08/05/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRFirmwareDownloader.h"

@implementation FFRFirmwareDownloader

- (void) downloadFirmwareDataFromURL: (NSString*) urlString
	callback: (void(^)(NSData* data))callback
{
	//NSURLSession* session = [NSURLSession sharedSession];
	NSURLSession* session = [NSURLSession
		sessionWithConfiguration: [NSURLSessionConfiguration defaultSessionConfiguration]
		delegate: nil
		delegateQueue: [NSOperationQueue mainQueue]];
	NSURL* url = [NSURL URLWithString: urlString];
	NSURLSessionDataTask* task = [session
		dataTaskWithURL: url
		completionHandler: ^void(NSData* data, NSURLResponse* response, NSError* error)
		{
			if (error == nil)
			{
				// Success.
            	callback(data);
        	}
			else
			{
				// Fail.
            	callback(nil);
        	}
		}];
	[task resume];
}

@end
