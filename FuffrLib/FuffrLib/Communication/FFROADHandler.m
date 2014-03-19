//
//  FFROADHandler.m
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-11-13.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFROADHandler.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "FFRBLEExtensions.h"
#import "FFRoad.h"


@implementation FFROADHandler


#define HI_UINT16(a) (((a) >> 8) & 0xff)
#define LO_UINT16(a) ((a) & 0xff)

NSString* const tiOADService =              @"0xF000FFC0-0451-4000-B000-000000000000";
NSString* const tiOADImageNotify =          @"0xF000FFC1-0451-4000-B000-000000000000";
NSString* const tiOADImageBlockRequest =    @"0xF000FFC2-0451-4000-B000-000000000000";

NSString* const FFRProgrammingNotification = @"FFRProgrammingNotification";
NSString* const FFRProgrammingUserInfoStateKey = @"FFRProgrammingStateKey";
NSString* const FFRProgrammingUserInfoProgressKey = @"FFRProgrammingProgressKey";
NSString* const FFRProgrammingUserInfoTimeLeftKey = @"FFRProgrammingTimeLeftKey";


@synthesize state = _state;

-(instancetype) init {
    if (self = [super init]) {
        _state = FFRProgrammingStateIdle;
        _dataBuffer = NULL;
    }

    return self;
}

-(id) initWithPeripheral:(CBPeripheral *)peripheral {
    if (self = [self init]) {
        [self loadPeripheral:peripheral];
    }

    return self;
}

-(void) loadPeripheral:(CBPeripheral*) peripheral {
    _imageDetected = FALSE;
    _peripheral = peripheral;
    [self configureProfile];
}

-(void) dealloc {
    [self deconfigureProfile];
    [self clearBuffer];
}

-(void) storeToBuffer:(NSData*) data {
    [self clearBuffer];
    _dataBuffer = malloc(data.length);
    [data getBytes:_dataBuffer];
}

-(void) clearBuffer {
    if (_dataBuffer != NULL) {
        free(_dataBuffer);
        _dataBuffer = NULL;
    }
}

#pragma mark - Bluetooth handling

-(void) configureProfile {
    NSLog(@"Configuring OAD Profile for peripheral: %@, delegate: %@", _peripheral, _peripheral.delegate);

    [_peripheral setNotificationForCharacteristicWithIdentifier:tiOADImageNotify enabled:TRUE];

    unsigned char data = 0x00;
    [_peripheral writeCharacteristicWithIdentifier:tiOADImageNotify data:[NSData dataWithBytes:&data length:1]];

    _currentImageVersion = 0xFFFF;
    [self performSelector:@selector(imageDetectTimerTick:) withObject:nil afterDelay:1.5];
    
    /*
    self.start = TRUE;*/
}

-(void) imageDetectTimerTick:(id)sender {
    // IF we have come here, the image userID is B.
    NSLog(@"imageDetectTimerTick:");
    unsigned char data = 0x01;
    [_peripheral writeCharacteristicWithIdentifier:tiOADImageNotify data:[NSData dataWithBytes:&data length:1]];
}

-(void) deconfigureProfile {
    NSLog(@"Deconfiguring OAD Profile");

    [_peripheral setNotificationForCharacteristicWithIdentifier:tiOADImageNotify enabled:TRUE];
}

#pragma mark - Bluetooth delegate

-(void) didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic {
    LOGMETHOD

    if ([characteristic.UUID isEqualToString:tiOADImageNotify]) {
        _imageDetected = TRUE;

        if (_currentImageVersion == 0xFFFF) {
            unsigned char data[characteristic.value.length];
            [characteristic.value getBytes:&data];

            _currentImageVersion = ((uint16_t)data[1] << 8 & 0xff00) | ((uint16_t)data[0] & 0xff);
            NSLog(@"self.imgVersion: %04hx", _currentImageVersion);
        }

        NSLog(@"OAD Image notify: %@", characteristic.value);
    }
}

-(void) didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //NSLog(@"didWriteValueForCharacteristic: %@", characteristic);
}

-(void)deviceDisconnected:(CBPeripheral *)peripheral {
    if ([peripheral isEqual:_peripheral] && _state == FFRProgrammingStateWriting) {
        _state = FFRProgrammingStateFailedDueToDeviceDisconnect;

        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"FW Upgrade Failed!" message:@"Device disconnected during programming, firmware upgrade was not finished!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];

        [[NSNotificationCenter defaultCenter] postNotificationName:FFRProgrammingNotification object:self userInfo:@{FFRProgrammingUserInfoProgressKey: @0.0f, FFRProgrammingUserInfoStateKey:[NSNumber numberWithInt:self.state], FFRProgrammingUserInfoTimeLeftKey: @0}];
    }
}

#pragma mark - image handling

-(BOOL) validateAndLoadImage:(NSString *)filename {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filename isDirectory:FALSE]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image does not exist!" message:[NSString stringWithFormat:@"Image '%@' was not found", filename] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
        return FALSE;
    }

    NSData* data = [NSData dataWithContentsOfFile:filename];
    NSLog(@"Loaded firmware '%@' of size: %lu", filename, (unsigned long)data.length);

    if (_imageDetected && [self verifyCorrectImage:data]) {
        [self uploadImage:data];
        return TRUE;
    }
    else if (_currentImageVersion == 0xFFFF) {
        UIAlertView *wrongImage = [[UIAlertView alloc] initWithTitle:@"Error connecting" message:@"The image on the device has not yet been determined" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [wrongImage show];
    }
    else {
        UIAlertView *wrongImage = [[UIAlertView alloc] initWithTitle:@"Wrong image type!" message:[NSString stringWithFormat:@"Selected image was of type: %c, which is the same as on the peripheral, please select another image", (_currentImageVersion & 0x01) ? 'B' : 'A'] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [wrongImage show];
    }

    return FALSE;
}

-(BOOL) verifyCorrectImage:(NSData*)data {
    unsigned char imageFileData[data.length];
    [data getBytes:imageFileData];

    img_hdr_t imgHeader;
    memcpy(&imgHeader, &imageFileData[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));

    if ((imgHeader.ver & 0x01) != (_currentImageVersion & 0x01)) {
        return YES;
    }
    else {
        return NO;
    }
}

-(void) uploadImage:(NSData*)image {
    _state = FFRProgrammingStateWriting;
    [self storeToBuffer:image];

    uint8_t requestData[OAD_IMG_HDR_SIZE + 2 + 2]; // 12Bytes

    for (int ii = 0; ii < 20; ii++) {
        NSLog(@"%02hhx", _dataBuffer[ii]);
    }

    img_hdr_t imgHeader;
    memcpy(&imgHeader, &_dataBuffer[0 + OAD_IMG_HDR_OSET], sizeof(img_hdr_t));

    requestData[0] = LO_UINT16(imgHeader.ver);
    requestData[1] = HI_UINT16(imgHeader.ver);
    requestData[2] = LO_UINT16(imgHeader.len);
    requestData[3] = HI_UINT16(imgHeader.len);

    NSLog(@"Image version = %04hx, len = %04hx, %d, %lu", imgHeader.ver, imgHeader.len, imgHeader.len, (unsigned long)image.length);

    memcpy(requestData + 4, &imgHeader.uid, sizeof(imgHeader.uid));

    requestData[OAD_IMG_HDR_SIZE + 0] = LO_UINT16(12);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(12);

    requestData[OAD_IMG_HDR_SIZE + 2] = LO_UINT16(15);
    requestData[OAD_IMG_HDR_SIZE + 1] = HI_UINT16(15);

    [_peripheral writeCharacteristicWithIdentifier:tiOADImageNotify data:[NSData dataWithBytes:requestData length:OAD_IMG_HDR_SIZE + 2 + 2]];

    // calculate blocks to send
    nBlocks = imgHeader.len / (OAD_BLOCK_SIZE / HAL_FLASH_WORD_SIZE);
    nBytes = imgHeader.len * HAL_FLASH_WORD_SIZE;
    iBlocks = 0;
    iBytes = 0;

    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
}

-(void) programmingTimerTick:(NSTimer*) timer {
    // stop transfer
    if (self.state == FFRProgrammingStateCancelRequested || self.state == FFRProgrammingStateFailedDueToDeviceDisconnect) {
        _state = FFRProgrammingStateIdle;
        return;
    }

    //Prepare Block
    uint8_t requestData[2 + OAD_BLOCK_SIZE];

    // This block is run 4 times, this is needed to get CoreBluetooth to send consequetive packets in the same connection interval.
    for (int ii = 0; ii < 4; ii++) {
        requestData[0] = LO_UINT16(iBlocks);
        requestData[1] = HI_UINT16(iBlocks);

        memcpy(&requestData[2] , &_dataBuffer[iBytes], OAD_BLOCK_SIZE);

        // log data
        /*NSMutableString* log = [NSMutableString string];
        for (int i = 0; i < 2 + OAD_BLOCK_SIZE; ++i) {
            [log appendFormat:@"%c", requestData[i]];
        }

        NSLog(@"data send: %@", log);*/

        [_peripheral writeCharacteristicWithoutResponseForIdentifier:tiOADImageBlockRequest data:[NSData dataWithBytes:requestData length:2 + OAD_BLOCK_SIZE]];

        iBlocks++;
        iBytes += OAD_BLOCK_SIZE;

        if (iBlocks == nBlocks) {
            _state = FFRProgrammingStateWriteCompleted;
            [[NSNotificationCenter defaultCenter] postNotificationName:FFRProgrammingNotification object:self userInfo:@{FFRProgrammingUserInfoProgressKey: @1.0f, FFRProgrammingUserInfoStateKey:[NSNumber numberWithInt:self.state], FFRProgrammingUserInfoTimeLeftKey: @0}];
            _state = FFRProgrammingStateIdle;
            return;
        }
        else {
            if (ii == 3) {
                [NSTimer scheduledTimerWithTimeInterval:0.09 target:self selector:@selector(programmingTimerTick:) userInfo:nil repeats:NO];
            }
        }
    }

    float progress = (float)iBlocks / (float)nBlocks;
    float secondsLeft = 0.09 / 4 * (nBlocks - iBlocks);
    [[NSNotificationCenter defaultCenter] postNotificationName:FFRProgrammingNotification object:self userInfo:@{FFRProgrammingUserInfoProgressKey: [NSNumber numberWithFloat:progress], FFRProgrammingUserInfoStateKey:[NSNumber numberWithInt:self.state], FFRProgrammingUserInfoTimeLeftKey: [NSNumber numberWithFloat:secondsLeft]}];
}


@end
