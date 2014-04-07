//
//  FFRTrackingArray.m
//  FuffrLib
//
//  Created by Fuffr on 2013-10-23.
//  Copyright (c) 2013 Fuffr. All rights reserved.
//

#import "FFRTrackingManager.h"


NSString* const FFRTrackingBeganNotification = @"FFRTrackingBeganNotification";
NSString* const FFRTrackingMovedNotification = @"FFRTrackingMovedNotification";
NSString* const FFRTrackingPulsedNotification = @"FFRTrackingPulsedNotification";
NSString* const FFRTrackingEndedNotification = @"FFRTrackingEndedNotification";

const float FFRTrackingManagerUpdateSpeed = 0.07f;


@interface FFRTrackingManager ()

-(void) addTrackingObject:(FFRTouch*) data;
-(void) removeTrackingObject:(FFRTouch *)data;
-(FFRTouch *) objectInTrackedObjectsWithIdentifier:(NSUInteger)identifier;

@end

@implementation FFRTrackingManager

@synthesize trackedObjects = _trackedObjects;

-(id) init {
    if (self = [super init]) {
        self.trackedObjects = [[NSMutableArray alloc] init];
        _timer = [NSTimer scheduledTimerWithTimeInterval:FFRTrackingManagerUpdateSpeed target:self selector:@selector(timerPrune:) userInfo:nil repeats:TRUE];
    }

    return self;
}

-(void) dealloc {
    while ([_trackedObjects count]) {
        [self removeTrackingObject:[self.trackedObjects objectAtIndex:0]];
    }

    _timer = nil;
}

#pragma mark -

-(void) handleNewOrChangedTrackingObject:(FFRTouch*) data {
    FFRTouch * existing = [self objectInTrackedObjectsWithIdentifier:data.identifier];
    if (existing) {
        existing.timestamp = data.timestamp;
        if (existing.location.x != data.location.x || existing.location.y != data.location.y)
		{
            existing.rawPoint = data.rawPoint;
            existing.normalizedLocation = data.normalizedLocation;
            //existing.phase = data.phase;
            existing.phase = UITouchPhaseMoved;
            existing.location = data.location;
        }
        else {

			//NSLog(@"! touch unchanged side: %i id: %i", (int)data.side, (int)data.identifier);

            [[NSNotificationCenter defaultCenter] postNotificationName:FFRTrackingPulsedNotification object:[NSSet setWithArray:_trackedObjects] userInfo:nil];
        }
    }
    else {
		//NSLog(@"! touch NEW side: %i id: %i", (int)data.side, (int)data.identifier);
        [self addTrackingObject:data];
    }
}

-(void) addTrackingObject:(FFRTouch *)data {
    LOGMETHOD

    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[_trackedObjects count]] forKey:@"trackedObjects"];
    [_trackedObjects insertObject:data atIndex:[_trackedObjects count]];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[_trackedObjects count]] forKey:@"trackedObjects"];

    [data addObserver:self forKeyPath:@"location" options:NSKeyValueObservingOptionNew context:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FFRTrackingBeganNotification object:[NSSet setWithArray:_trackedObjects] userInfo:nil];
    });
}

-(void) removeTrackingObject:(FFRTouch *)data {
    LOGMETHOD

    NSUInteger index = [self indexForTouch:data.identifier];
    if (index == INT_MAX) {
        return;
    }

    FFRTouch* t = [_trackedObjects objectAtIndex:index];
    t.phase = UITouchPhaseEnded;

    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"trackedObjects"];
    [_trackedObjects removeObjectAtIndex:index];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"trackedObjects"];

    [data removeObserver:self forKeyPath:@"location"];

    NSMutableSet* set = [NSMutableSet setWithArray:_trackedObjects];
    [set addObject:t];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FFRTrackingEndedNotification object:set userInfo:nil];
    });
}

#pragma mark - 

-(void) timerPrune:(id) sender {
    NSMutableArray* old = [NSMutableArray array];
    NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
    for (FFRTouch* t in self.trackedObjects) {
        if (now - t.timestamp >= 3 * FFRTrackingManagerUpdateSpeed) {
            [old addObject:t];
        }
    }

    for (FFRTouch* t in old) {
        [self removeTrackingObject:t];
    }
}

#pragma mark - Tracking lookup

-(FFRTouch *) objectInTrackedObjectsWithIdentifier:(NSUInteger)identifier {
    NSUInteger index = [self indexForTouch:identifier];
    if (index == INT_MAX) {
        return nil;
    }
    else {
        return [_trackedObjects objectAtIndex:index];
    }
}

-(NSUInteger) indexForTouch:(NSUInteger)identifier {
    NSUInteger index = INT_MAX;
    for (int i = 0; i < [_trackedObjects count]; ++i) {
        FFRTouch* t = [_trackedObjects objectAtIndex:i];
        if (t.identifier == identifier) {
            index = i;
            break;
        }
    }

    return index;
}

#pragma mark - 
-(void) observeValueForKeyPath:(NSString *)keyPath
	ofObject:(id)object
	change:(NSDictionary *)change
	context:(void *)context
{
    //LOGMETHOD

    if ([keyPath compare:@"location"] == NSOrderedSame) {
        NSValue* value = [change objectForKey:NSKeyValueChangeNewKey];
        FFRTouch* t = object;
        t.phase = UITouchPhaseMoved;
        [[NSNotificationCenter defaultCenter] postNotificationName:FFRTrackingMovedNotification object:[NSSet setWithArray:_trackedObjects] userInfo:@{@"location": value}];
    }
}


@end
