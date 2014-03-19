//
//  RawTrackingData.h
//  FuffrLib
//
//  Created by Christoffer Sjöberg on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#ifndef FFRRawTrackingData_h
#define FFRRawTrackingData_h

/**
    Data struct as delivered from the sensor case
 */
typedef struct {
    /**
     which side the data comes from
     */
    Byte identifier;

    /**
     x-coordinate low bits
     */
    Byte lowX;

    /**
     x-coordinate high bits
     */
    Byte highX;

    /**
     y-coordinate low bits
     */
    Byte lowY;

    /**
     y-coordinate high bits
     */
    Byte highY;
} FFRRawTrackingData;

#endif
