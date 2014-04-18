//
//  FFRGestureManager.h
//  FuffrLib
//
//  Created by Fuffr on 2013-11-21.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

// TODO: Remove class!

#ifdef NOT_DEFINED_AT_ALL

#import <Foundation/Foundation.h>


@class FFRGestureRecognizer;

/**
 Manager to create events that gesture recognizers can act on
 */
@interface FFRGestureManager : NSObject {
    NSMutableArray* _recognizers;
}

/**
 shared instance
 */
+(instancetype) sharedManager;

/**
 Method to register a recognizer with the manager, done automatically from UIView category
 */
-(void) addGestureRecognizer:(FFRGestureRecognizer*)recognizer;

/**
 Method to unregister a recognizer with the manager, done automatically from UIView category
 */
-(void) removeGestureRecognizer:(FFRGestureRecognizer*)recognizer;

@end

#endif
