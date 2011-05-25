//
//  CSGCamera.h
//  MotionTracker
//
//  Created by Tim Omernick on 3/7/05.
//  Copyright 2005 Tim Omernick. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

@interface CSGCamera : NSObject
{
    id							delegate;
    SeqGrabComponent			component;
    SGChannel					channel;
    GWorldPtr					gWorld;
    Rect						boundsRect;
    ImageSequence				decompressionSequence;
    TimeScale					timeScale;
    TimeValue					lastTime;
	NSTimeInterval				startTime;
    NSTimer						*frameTimer;
	BOOL						running;
}

- (void)setDelegate:(id)newDelegate;
- (BOOL)startWithSize:(NSSize)frameSize;
- (BOOL)stop;
- (void)showSettingsDialog;
- (BOOL)isRunning;

@end

@interface NSObject (Private)
- (void)camera:(CSGCamera *)aCamera didReceiveFrame:(void *)pixelDataPointer;
@end
