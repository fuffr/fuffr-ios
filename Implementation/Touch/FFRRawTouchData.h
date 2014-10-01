//
//  FFRRawTouchData.h
//  FuffrLib
//
//  Created by Fuffr on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#ifndef FFRRawTouchData_h
#define FFRRawTouchData_h

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
} FFRRawTouchData;

#endif
