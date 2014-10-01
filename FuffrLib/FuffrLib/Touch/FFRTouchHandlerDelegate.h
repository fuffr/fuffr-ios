//
//  FFRTouchHandlerDelegate.h
//  FuffrLib
//
//  Created by miki on 01/10/14.
//  Copyright (c) 2014 Fuffr. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FFRTouchHandlerDelegate <NSObject>

- (void) touchesBegan: (NSSet*)touches;
- (void) touchesMoved: (NSSet*)touches;
- (void) touchesEnded: (NSSet*)touches;

@end
