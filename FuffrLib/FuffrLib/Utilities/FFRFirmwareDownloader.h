//
//  FFRFirmwareDownloader.h
//  FuffrLib
//
//  Created by miki on 08/05/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFRFirmwareDownloader : NSObject

/*
Format of firmware URL list file:

<firmware-list>
	<firmware-entry>
		<firmware-key>CC2541-A</firmware-key>
		<firmware-url>http://demos.fuffr.com/firmware/IPHONE_CASE_R04_CC2541_IMG_A_1_2_0_0.bin</firmware-url>
	</firmware-entry>
	<firmware-entry>
		<firmware-key>CC2541-B</firmware-key>
		<firmware-url>http://demos.fuffr.com/firmware/IPHONE_CASE_R04_CC2541_IMG_B_1_2_0_0.bin</firmware-url>
	</firmware-entry>
	<firmware-entry>
		<firmware-key>MSP430-A</firmware-key>
		<firmware-url>http://demos.fuffr.com/firmware/IPHONE_CASE_R04_MSP430_IMG_A_1_5_1_0.bin</firmware-url>
	</firmware-entry>
	<firmware-entry>
		<firmware-key>MSP430-B</firmware-key>
		<firmware-url>http://demos.fuffr.com/firmware/IPHONE_CASE_R04_MSP430_IMG_B_1_5_1_0.bin</firmware-url>
	</firmware-entry>
</firmware-list>
*/

/**
 * Download firmware file.
 * @param firmwareId - image id "CC2541" or "MSP430".
 * @param version - image version, is 'A' or 'B'.
 */
 - (void) downloadFirmware: (NSString*)firmwareId
	version: (char)version
	callback: (void(^)(NSData* data))callback;

@end
