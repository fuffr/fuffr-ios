//
//  FFRGestureRecognizer.m
//  FuffrLib
//
//  Created by Fuffr on 2013-11-08.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRGestureRecognizer.h"

@implementation TargetActionPair

@synthesize target = _target;
@synthesize action = _action;

@end

@implementation FFRGestureRecognizer

-(id) init {
	if (self = [super init]) {
		_actionPairs = [NSMutableArray array];
		self.state = FFRGestureRecognizerStateUnknown;
	}

	return self;
}

-(CGFloat) maxDistanceBetween:(CGPoint)point1 andPoint:(CGPoint)point2 {
	return MAX(ABS(point1.x-point2.x), ABS(point1.y-point2.y));
}

-(CGFloat) distanceBetween:(CGPoint)point1 andPoint:(CGPoint)point2 {
	return sqrt((point1.x-point2.x)*(point1.x-point2.x) + (point1.y-point2.y)*(point1.y-point2.y));
}

-(void) addTarget:(id)target action:(SEL)action {
	TargetActionPair* pair = [[TargetActionPair alloc] init];
	pair.target = target;
	pair.action = action;

	[_actionPairs addObject:pair];
}

-(void) performAction {
	LOGMETHOD
	
	for (TargetActionPair* pair in _actionPairs) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[pair.target performSelector:pair.action withObject:self];
#pragma clang diagnostic pop
	}
}

-(void) performActionWithObject: (id)object {
	LOGMETHOD
	
	for (TargetActionPair* pair in _actionPairs) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[pair.target performSelector:pair.action withObject:object];
#pragma clang diagnostic pop
	}
}

-(void) touchesBegan:(NSSet*)touches {
}

-(void) touchesMoved:(NSSet *)touches {
}

-(void) touchesEnded:(NSSet *)touches {
}

@end
