//	http://developer.apple.com/documentation/QuickTime/Conceptual/QT7-1_Update_Guide/index.html - READ THIS
//  Will allow me to drop gWorlds and use a direct to opengl texture transfer. Use a pointer to the texture to reduce
//	code in the hudview image to texture code.

#import "CSGCamera.h"

@interface CSGCamera (Private)
- (void)_sequenceGrabberIdle;
- (BOOL)_setupDecompression;
- (void)_didUpdate;
- (unsigned char *)_imageFromGWorld:(GWorldPtr)gworld;
@end

@interface CSGCamera (SequenceGrabber)
	pascal OSErr CSGCameraSGDataProc(
		SGChannel channel,
		Ptr data,
		long dataLength,
		long *offset,
		long channelRefCon,
		TimeValue time,
		short writeType,
		long refCon);
@end

@implementation CSGCamera

// Init and dealloc

- (void)dealloc;
{
	[self stop];
	[delegate release];
	[super dealloc];
}

// API

- (void)setDelegate:(id)newDelegate;
{
    if (delegate == newDelegate)
        return;
        
    [delegate release];
    delegate = [newDelegate retain];
}

- (BOOL)startWithSize:(NSSize)frameSize;
{
    OSErr theErr;
	
    timeScale = 0;
    lastTime = 0;
    
    // Initialize movie toolbox
    theErr = EnterMovies();
    if (theErr != noErr)
        return NO;
    
    // Open default sequence grabber component
    component = OpenDefaultComponent(SeqGrabComponentType, 0);
    if (!component)
        return NO;
    
    // Initialize sequence grabber component
    theErr = SGInitialize(component);
    if (theErr != noErr)
        return NO;
    
    // Don't make movie
    theErr = SGSetDataRef(component, 0, 0, seqGrabDontMakeMovie);
    if (theErr != noErr)
        return NO;
    
    // Create sequence grabber video channel
    theErr = SGNewChannel(component, VideoMediaType, &channel);
    if (theErr != noErr)
        return NO;
    
    // Set the grabber's bounds
    boundsRect.top = 0;
    boundsRect.left = 0;
    boundsRect.bottom = frameSize.height;
    boundsRect.right = frameSize.width;
    
    theErr = SGSetChannelBounds(component, &boundsRect);
    
    // Create the GWorld
    theErr = QTNewGWorld(&gWorld, k32ARGBPixelFormat, &boundsRect, 0, NULL, 0);
    if (theErr != noErr)
		return NO;
    
    // Lock the pixmap
    if (!LockPixels(GetPortPixMap(gWorld)))
        return NO;
    
    // Set GWorld
    theErr = SGSetGWorld(component, gWorld, GetMainDevice());
    if (theErr != noErr)
        return NO;
    
    // Set the channel's bounds
    theErr = SGSetChannelBounds(channel, &boundsRect);
    if (theErr != noErr)
		return NO;
    
    // Set the channel usage to record
    theErr = SGSetChannelUsage(channel, seqGrabRecord);
    if (theErr != noErr)
        return NO;
    
    // Set data proc
    theErr = SGSetDataProc(component, NewSGDataUPP(&CSGCameraSGDataProc), (long)self);
    if (theErr != noErr)
        return NO;
    
    // Prepare
    theErr = SGPrepare(component, false, true);
    if (theErr != noErr)
        return NO;
    
    // Start recording
    theErr = SGStartRecord(component);
    if (theErr != noErr)
        return NO;

	startTime = [NSDate timeIntervalSinceReferenceDate];
	
    // Set up decompression sequence (camera -> GWorld)
    [self _setupDecompression];
    
    // Start frame timer
    frameTimer = [[NSTimer scheduledTimerWithTimeInterval:1/15.0f
		target:self
		selector:@selector(_sequenceGrabberIdle)
		userInfo:nil
		repeats:YES] retain];
        
    [self retain]; // Matches autorelease in -stop
    running = YES;
    return YES;
}

- (BOOL)stop;
{    
    // Stop frame timer
	if (frameTimer) {
		[frameTimer invalidate];
		[frameTimer release];
		frameTimer = nil;
	}
    
    // Stop recording
	if (component)
		SGStop(component);
    
    ComponentResult theErr;

    // End decompression sequence
	if (decompressionSequence) {
		theErr = CDSequenceEnd(decompressionSequence);
		if (theErr != noErr)
			NSBeep();
		decompressionSequence = 0;
	}
    
    // Close sequence grabber component
	if (component) {
		theErr = CloseComponent(component);
		if (theErr != noErr)
			NSBeep();
		component = NULL;
	}
    
    // Dispose of GWorld
	if (gWorld) {
		DisposeGWorld(gWorld);
		gWorld = NULL;
	}
    
    [self autorelease]; // Matches retain in -start
    running = NO;
    return YES;
}

- (void)_sequenceGrabberIdle;
{
    OSErr theErr;
    
    theErr = SGIdle(component);
    if (theErr != noErr)
        return;
}

- (BOOL)_setupDecompression;
{
    ComponentResult theErr;
    
    ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
    theErr = SGGetChannelSampleDescription(channel, (Handle)imageDesc);
    if (theErr != noErr)
		return NO;
    
    Rect sourceRect;
    sourceRect.top = 0;
    sourceRect.left = 0;
    sourceRect.right = (**imageDesc).width;
    sourceRect.bottom = (**imageDesc).height;
    
    MatrixRecord scaleMatrix;
    RectMatrix(&scaleMatrix, &sourceRect, &boundsRect);
    
    theErr = DecompressSequenceBegin(
		&decompressionSequence,
		imageDesc,
		gWorld,
		NULL,
		NULL,
		&scaleMatrix,
		srcCopy,
		NULL,
		0,
		codecNormalQuality,
		bestSpeedCodec);
		
    if (theErr != noErr)
        return NO;
    
    DisposeHandle((Handle)imageDesc);
	
	return YES;
}

- (void)_didUpdate;
{
    if ([delegate respondsToSelector:@selector(camera:didReceiveFrame:)]) {
        void *thePointer = [self _imageFromGWorld:gWorld];
        [delegate camera:self didReceiveFrame:thePointer];
    }
}

- (unsigned char *)_imageFromGWorld:(GWorldPtr)gworld;
{
    NSParameterAssert( gworld != NULL );

    PixMapHandle pixMapHandle = GetGWorldPixMap( gworld );
    if ( LockPixels( pixMapHandle ) )
    {
        void *pixBaseAddr = GetPixBaseAddr(pixMapHandle);
        UnlockPixels( pixMapHandle );
		return pixBaseAddr;
    }
    
    return NULL;
}

- (void)showSettingsDialog
{
	SGSettingsDialog (component,channel,0,NULL,0,NULL,0);
	//[self startWithSize: NSMakeSize(320,240)];
}

-(BOOL)isRunning
{
	return running;
}

@end

@implementation CSGCamera (SequenceGrabber)

pascal OSErr CSGCameraSGDataProc(
	SGChannel channel,
	Ptr data,
	long dataLength,
	long *offset,
	long channelRefCon,
	TimeValue time,
	short writeType,
	long refCon)
{
    CSGCamera *camera = (CSGCamera *)refCon;
    ComponentResult theErr;
    
    if (camera->timeScale == 0) {
        theErr = SGGetChannelTimeScale(camera->channel, &camera->timeScale);
        if (theErr != noErr)
            return theErr;
    }
    
    if (camera->gWorld) {
        CodecFlags ignore;
        theErr = DecompressSequenceFrameS(camera->decompressionSequence, data, dataLength, 0, &ignore, NULL);
        if (theErr != noErr)
            return theErr;
    }
    
    camera->lastTime = time;
    
    [camera _didUpdate];
    
    return noErr;
}

@end
