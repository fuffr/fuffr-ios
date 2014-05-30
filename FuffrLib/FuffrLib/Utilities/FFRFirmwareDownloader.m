//
//  FFRFirmwareDownloader.m
//  FuffrLib
//
//  Created by miki on 08/05/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import "FFRFirmwareDownloader.h"

// For format of firmware URL list, see header file.

@implementation FFRFirmwareDownloader

// Public methods.

- (void) downloadFirmware: (NSString*)firmwareId
	version: (char)version
	callback: (void(^)(NSData* data))callback
{
	// Download url list.
	[self downloadImageVersionFile:
		^void(NSString* urlList)
		{
			if (urlList)
			{
				// Find position of firmware key in url list.
				NSString* firmwareName = [NSString stringWithFormat:@"%@-%c", firmwareId, version];
				int index = XMLTagWithContentStartIndex(
					urlList,
					@"firmware-key",
					firmwareName,
					0);
				if (index == -1)
				{
					// Firmware key not found.
					callback(nil);
					return;
				}

				// Get the firmware URL from the url list.
				NSString* firmwareURL = XMLTagContent(
					urlList,
					@"firmware-url",
					index);

				NSLog(@"firmware url: %@", firmwareURL);

				if (!firmwareURL)
				{
					// Firmware URL not found.
					callback(nil);
					return;
				}

				// Download firmware data file. Result is passed to callback block.
            	[self
					downloadDataFromURL: firmwareURL
					callback: callback];
        	}
			else
			{
				NSLog(@"URL list not found");
				// URL list not found.
				callback(nil);
			}
		}];
}

// Helper functions for "well-formed" XML data (must follow our conventions ;)

int XMLTagWithContentStartIndex(
	NSString* xmlData,
	NSString* tag,
	NSString* tagContent,
	int start)
{
	// Find start of data to search.
	NSString* data = [xmlData substringFromIndex: start];

	// Find substring.
	NSString* findMe = [NSString stringWithFormat: @"<%@>%@</%@>", tag, tagContent, tag];
	NSRange range = [data rangeOfString: findMe];

	if (range.location != NSNotFound)
	{
		return (int)range.location;
	}
	else
	{
		return -1;
	}
}

NSString* XMLTagContent(NSString* xmlData, NSString* tag, int start)
{
	// Find start of data to search.
	NSString* data = [xmlData substringFromIndex: start];

	// Find start tag and stop tag.
	NSString* startTag = [NSString stringWithFormat: @"<%@>", tag];
	NSString* stopTag = [NSString stringWithFormat: @"</%@>", tag];
	NSRange startRange = [data rangeOfString: startTag];
	NSRange stopRange = [data rangeOfString: stopTag];

	if (startRange.location != NSNotFound && stopRange.location != NSNotFound)
	{
		// Get tag content by stripping down data.
		NSUInteger startIndex = startRange.location + startTag.length;
		data = [data substringFromIndex: startIndex];
		data = [data substringToIndex: (stopRange.location - startIndex)];
		return data;
	}
	else
	{
		return nil;
	}
}

// Private methods.

- (void) downloadDataFromURL: (NSString*) urlString
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

- (void) downloadImageVersionFile: (void(^)(NSString* data))callback
{
	[self
		downloadDataFromURL: @"http://evomedia.evothings.com/fuffr/firmware/firmware.lst"
		callback: ^void(NSData* data)
		{
			if (data)
			{
				NSString* urlList = [[NSString alloc]
					initWithData: data
					encoding: NSUTF8StringEncoding];
            	callback(urlList);
        	}
			else
			{
				callback(nil);
			}
		}];
}

@end
