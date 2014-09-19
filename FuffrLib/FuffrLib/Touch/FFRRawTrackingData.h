//
//  RawTrackingData.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#ifndef FFRRawTrackingData_h
#define FFRRawTrackingData_h

/**
 * Touch data.
 */
typedef struct
{
	/**
	 * Touch id.
	 */
	Byte identifier : 5;

	/**
	 * Touch status:
	 * 0 for up;
	 * 1 for down;
	 */
	Byte down : 1;

	//Byte typeAndIdentifier;

	/**
	 x-coordinate
	 */
	Byte x;

	/**
	 y-coordinate
	 */
	Byte y;
} FFRRawTrackingData;

#endif
