#import "MainController.h"

@implementation MainController

- (void)awakeFromNib
{
	//initialize joystick pooling timer
	control_mode = 1;
	control_needs_send = 0;
    selectedCraft = 0;
	theJoystick = [[JoystickController alloc] init];
	[self setupJoystickTimer];
	
	//initialize openglview MyHUDView
	[videoFeed initWithFrame: [videoFeed frame] colorBits:24 depthBits:24 fullscreen:FALSE ];
	
	//issue prefs change event to parse colors for hud and mission editor
    [self preferencesDidChange];
	
	//start opengl render timer
	if( videoFeed != nil )
		[ self setupRenderTimer ];
	
	//initialize camera timer and input
	camera = [[CSGCamera alloc] init];
	[camera setDelegate: self];
	[camera startWithSize: NSMakeSize(320,240)];
	
	//detach udp sampler thread
	[self startSampling: nil];
}

- (void)gotVideoSetup:(id)sender
{
    [renderTimer invalidate];
    [camera showSettingsDialog];
	[camera stop];
    [camera startWithSize: NSMakeSize(320,240)];
    [self setupRenderTimer];
}

- (void)preferencesDidChange
{
    NSUserDefaults      *defs = [NSUserDefaults standardUserDefaults];
    NSColor             *overlayHUDColorValue;
    NSColor             *overlayTextColorValue;
    
    if([defs dataForKey: @"overlayHUDColor"])
        overlayHUDColorValue = [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"overlayHUDColor"]];
    else
        overlayHUDColorValue = [NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:1];

    if([defs dataForKey: @"overlayTextColor"])
        overlayTextColorValue = [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"overlayTextColor"]];
    else
        overlayTextColorValue = [NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:1];
    
    float           textColor[4] = {
        [overlayTextColorValue redComponent],
        [overlayTextColorValue greenComponent],
        [overlayTextColorValue blueComponent],
        [overlayTextColorValue alphaComponent]};
    float           hudColor[4] = {
        [overlayHUDColorValue redComponent],
        [overlayHUDColorValue greenComponent],
        [overlayHUDColorValue blueComponent],
        [overlayHUDColorValue alphaComponent]};
    
	[videoFeed setOverlayColorAtIndex: 0 toColor: hudColor];
    [videoFeed setOverlayColorAtIndex: 1 toColor: textColor];
}

- (IBAction)resetJoystickController:(id)Sender
{
	[theJoystick dealloc];
	theJoystick = [[JoystickController alloc] init];
	[self setupJoystickTimer];
}

- (IBAction)showMapWindow:(id)sender
{
	if(!missionWindowController) {
		missionWindowController=[[MissionWindowController alloc] init];
        [missionWindowController setDelegate: self];
    }
		
	[[missionWindowController window] makeKeyAndOrderFront:nil];
}

- (IBAction)showAutopilotWindow:(id)sender
{
	if(!autopilotWindowController)
		autopilotWindowController=[[AutopilotWindowController alloc] init];
		
	[[autopilotWindowController window] makeKeyAndOrderFront:nil];
}

- (IBAction)showVideoWindow:(id)Sender
{
	if(![camera isRunning]){
		[camera startWithSize: NSMakeSize(320,240)];
		[self setupRenderTimer];
	}
	[mainWindow makeKeyAndOrderFront:nil];
}

-(BOOL)windowShouldClose:(NSNotification*)aNotification
{
	if([camera isRunning]){
		[renderTimer invalidate];
		[renderTimer release];
		[camera stop];
	}
	return YES;
}
	
- (void)setupJoystickTimer
{
	joystickTimer=[[NSTimer scheduledTimerWithTimeInterval:1/10.0f target:self selector:@selector( updateJoystickReadings: ) userInfo:nil repeats:YES ]retain];
}

- (IBAction)parseThrottleSlider:(id)sender
{
	throttle = [throttleTestSlider intValue];
	[videoFeed setThrottle: (throttle*100)/255];
}

- (void)updateJoystickReadings:(id)Sender
{	
	SInt32		buttons[8];
	int			i;
	
	if(theJoystick){
		aileron = [theJoystick returnAxisValue: AILERON_AXIS];
		elevator = [theJoystick returnAxisValue: ELEVATOR_AXIS];
		rudder = [theJoystick returnAxisValue: RUDDER_AXIS];
		throttle = [theJoystick returnAxisValue: THROTTLE_AXIS];
		
		if([sliderInvertCheckbox state]==NSOnState)
			throttle = 255-throttle;
	
		[xAxisSlider setIntValue: aileron];
		[yAxisSlider setIntValue: elevator];
		[zAxisSlider setIntValue: rudder];
		[sliderSlider setIntValue: throttle];
		
		buttons[0] = [theJoystick returnHatswitchValue];
		[hatswitch setIntValue: buttons[0]];
		
		for(i=1;i<8;i++)
			buttons[i] = [theJoystick returnButtonValue: i-1];
		
		[button1 setIntValue: buttons[1]];
		[button2 setIntValue: buttons[2]];
		[button3 setIntValue: buttons[3]];
		[button4 setIntValue: buttons[4]];
		[button5 setIntValue: buttons[5]];
		[button6 setIntValue: buttons[6]];
		[button7 setIntValue: buttons[7]];
		
		/* check desired_state[heading] */
		if(buttons[1]){
			control_needs_send=1;
			desired_state[selectedCraft][0] -= 1;
		}
		if(buttons[3]){
			control_needs_send=1;
			desired_state[selectedCraft][0] += 1;
		}
		/* check desired_state[altitude] */
		if(buttons[2]){
			control_needs_send=1;
			desired_state[selectedCraft][1] -= 10;
		}
		if(buttons[4]){
			control_needs_send=1;
			desired_state[selectedCraft][1] += 10;
		}
		/* check desired_state[airspeed] */
		if(buttons[5]){
			control_needs_send=1;
			desired_state[selectedCraft][2] += 5;
		}
		if(buttons[7]){
			control_needs_send=1;
			desired_state[selectedCraft][2] -= 5;
		}
		
		[videoFeed setDesiredState: (float *)&desired_state];
		
		/* do we need sending? */
		if(control_needs_send){
			if(buttons[6]){
				[self transmitControlPacket];
				control_needs_send = 0;
			}
		}
		
		//send throttle value to view
		[videoFeed setThrottle: (throttle*100)/255];
		if(control_mode == 1) /* full joystick relay */
			[self transmitControlStream];
	}
}

- (void)setControlNeedsSend:(id)sender
{
    desired_state[selectedCraft][0] = [desiredStateHeading floatValue];
    desired_state[selectedCraft][1] = [desiredStateAltitude floatValue];
    desired_state[selectedCraft][2] = [desiredStateAirspeed floatValue];
    [self transmitControlPacket];
    [videoFeed setDesiredState: (float *)&desired_state];
}

- (void)remapAxis:(int)axisIndex toValue:(int)mapIndex
{
	[theJoystick remapAxis: axisIndex toValue: mapIndex];
}

- (void)dealloc
{
	if( joystickTimer != nil && [ joystickTimer isValid ] )
		[ joystickTimer invalidate ];

	[ videoFeed release ];
	
	if( renderTimer != nil && [ renderTimer isValid ] )
		[ renderTimer invalidate ];

	[super dealloc];
}

- (IBAction)showPreferencesWindow:(id)sender
{
	if(!preferencesWindowController){
		preferencesWindowController = [[PreferencesWindowController alloc] init];
		[preferencesWindowController setDelegate: self];
		[[preferencesWindowController window] makeKeyAndOrderFront: nil];
	}
	else
		[[preferencesWindowController window] makeKeyAndOrderFront: nil];
}

- (IBAction)openMissionFromMenu:(id)sender
{
	//make sure the window is visible.
	[self showMapWindow:nil];
	//send the map window controller an open mission action
	[missionWindowController loadMission:nil];
}

- (IBAction)saveMissionFromMenu:(id)sender
{
	//make sure the window is visible.
	[self showMapWindow:nil];
	
	//send the map window controller an open mission action
	[missionWindowController saveMission:nil];
}

/*
	The following code creates an image of valid OpenGL texture size (512x256)
	which contains black area around original invalid (for OpenGL) image size.
	Then we return a pointer to the new image so OpenGL can texturize it.
*/
- (void)camera:(CSGCamera *)aCamera didReceiveFrame:(void *)pixelDataPointer;
{
	int x,y;
	
	//NSBitmapImageRep *destImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide: 512 pixelsHigh: 256 bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:3*512 bitsPerPixel:24];
	unsigned char *destData = malloc(393216);//[destImageRep bitmapData];
	unsigned char *p1,*p2;
	
	for(y=0;y<256;y++){
		for(x=0;x<512;x++){
			if(x<320 && y<240){
				p1 = pixelDataPointer + 4*(y*(320+4) + x);
				p2 = destData + 3*(y*512 + x);
				p2[0]=p1[1];
				p2[1]=p1[2];
				p2[2]=p1[3];
			}else{
				p2 = destData + 3*(y*512 + x);
				p2[0]=0;
				p2[1]=0;
				p2[2]=0;
			}
		}
	}
	
	[videoFeed setPicPointer: destData];
	[videoFeed loadGLTextures];
	free(destData);
}

- (IBAction)startSampling:(id)sender
{
	int result;
	int yes=1;
	
	bzero(&tel_sockaddress, sizeof(tel_sockaddress));
	bzero(&ctl_sockaddress, sizeof(ctl_sockaddress));
    bzero(&iph_sockaddress, sizeof(iph_sockaddress));
	
	tel_socket = socket(AF_INET, SOCK_DGRAM, 0); /* TELEMETRY RX */
	ctl_socket = socket(AF_INET, SOCK_DGRAM, 0); /* CONTROL TX */
    iph_socket = socket(AF_INET, SOCK_DGRAM, 0); /* iphone socket */
    
	tel_sockaddress.sin_family = AF_INET;
	ctl_sockaddress.sin_family = AF_INET;
    iph_sockaddress.sin_family = AF_INET;
	
    tel_sockaddress.sin_port = htons(1235);
	ctl_sockaddress.sin_port = htons(1236);
    iph_sockaddress.sin_port = htons(1237);
    
	tel_sockaddress.sin_addr.s_addr = htonl(INADDR_ANY);
	ctl_sockaddress.sin_addr.s_addr = inet_addr("255.255.255.255");
    iph_sockaddress.sin_addr.s_addr = htonl(INADDR_ANY);
    
	result = bind(tel_socket, (struct sockaddr *)&tel_sockaddress, sizeof(tel_sockaddress));
	result = setsockopt(ctl_socket, SOL_SOCKET, SO_BROADCAST, (char *)&yes, sizeof(yes));
    result = setsockopt(iph_socket, SOL_SOCKET, SO_BROADCAST, (char *)&yes, sizeof(yes));
	
	//detach thread now that the socket is ready and bind
	[NSThread detachNewThreadSelector:@selector(receiveTelemetryStream:) toTarget: self withObject: nil];
}

- (IBAction)stopSampling:(id)sender
{
	close(tel_socket);
	close(ctl_socket);
}

- (IBAction)showAboutPanel:(id)sender
{
	if ( !aboutWindow )
		[NSBundle loadNibNamed:@"AboutPanel" owner:self];
    
    [aboutWindow makeKeyAndOrderFront:nil];
}

- (void)updateAttitudeOfUAV:(int)uav
{
	//update hudview. no need to do it unless the update is of the monitored uav
	if (uav == selectedCraft) {
        [videoFeed setRoll: packet[selectedCraft][0]];
        [videoFeed setPitch: packet[selectedCraft][1]];
        [videoFeed setHeading: packet[selectedCraft][2]];
        [videoFeed setRadarAltitude: packet[selectedCraft][3]];
        [videoFeed setLatitude: packet[selectedCraft][4]];
        [videoFeed setLongitude: packet[selectedCraft][5]];
        [videoFeed setGpsAltitude: packet[selectedCraft][6]];
    }
    
    // map is always updated
    [missionWindowController setAircraftPoint:
        NSMakePoint(packet[uav][5],packet[uav][4])
        heading: packet[uav][2]
        desiredHeading: desired_state[uav][0]
        forAddress: uav];
}

- (IBAction)updateSelectedCraft:(id)sender
{
    selectedCraft = [sender indexOfItem: [sender selectedItem]];
    NSLog(@"Selected UAV: %d\n", selectedCraft);
}

- (void)receiveTelemetryStream:(id)sender
{
    /* change as of aug 2008. fixed packet length. no need for header and footer
       because packets are only read if their size is exact match */
	BOOL done = NO;
	unsigned int ret;
	unsigned int sin_length;
    char buffer;
	int i,uav_id;
    float l_packet[9];
	
	sin_length = sizeof(tel_sockaddress);
	
	while (!done) {
		ret = recvfrom(tel_socket, &buffer, 1, MSG_WAITALL, (struct sockaddr *)&tel_sockaddress, &sin_length);
		if(buffer=='A'){
			// got a packet start, retrieve float
			ret = recvfrom(tel_socket, &l_packet, sizeof(l_packet), MSG_WAITALL, (struct sockaddr *)&tel_sockaddress, &sin_length);
            // copy first 8 floats (9th is addr) to packet
            uav_id = htonl(l_packet[8]);
            printf("This packet is for UAV: %d\n", uav_id);
            memcpy(packet[uav_id], l_packet, 8*sizeof(float));
			
            for(i=0;i<8;i++)
				packet[uav_id][i] = [self ntohf: packet[uav_id][i]];


            [self updateAttitudeOfUAV: uav_id];
		}
	}
}

- (void)transmitControlStream
{
	unsigned int	sin_length;
	unsigned char	startstop[3] = {'A',0,'Z'};
	/* 0 is deflection stream, 1 is desired_state packet */
	float			joyBuffer[4];
	
	sin_length = sizeof(ctl_sockaddress);
	
	/* scale to [0, 2] and then to [-1,1] except throttle which scales directly to [0,1] */
	joyBuffer[0] = (aileron/127.5)-1.0;
	joyBuffer[1] = (elevator/127.5)-1.0;
	joyBuffer[2] = (rudder/127.5)-1.0;
	joyBuffer[3] = (throttle/255.0);
	
	sendto(ctl_socket, &startstop[0], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
	sendto(ctl_socket, &startstop[1], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
	sendto(ctl_socket, &joyBuffer, sizeof(joyBuffer), MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
	sendto(ctl_socket, &startstop[2], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
}

- (void)transmitControlPacket
{
	unsigned int sin_length;
	unsigned char startstop[3] = {'A',1,'Z'};
    float state_copy[3];
    int i;
    
    for(i=0;i<3;i++)
        state_copy[i] = [self ntohf:desired_state[selectedCraft][i]];
	
	sin_length = sizeof(ctl_sockaddress);
	
    // send desired states
    sendto(ctl_socket, &startstop[0], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
	sendto(ctl_socket, &startstop[1], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
	sendto(ctl_socket, state_copy, sizeof(state_copy), MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
	sendto(ctl_socket, &startstop[2], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
    
    // send autopilot mode
    unsigned char AP_HEADING = ((unsigned char) (1 << 0));
    unsigned char AP_ALTITUDE = ((unsigned char) (1 << 1));
    unsigned char AP_AIRSPEED = ((unsigned char) (1 << 2));
    unsigned char AP_WAYPOINT = ((unsigned char) (1 << 3));
    unsigned char AP_RCMANUAL = ((unsigned char) (1 << 4));
    // fill in the flags
    unsigned char output = 0;
    if ([missionMode state])
        output |= AP_WAYPOINT;
    if ([channelMode state] && [channelHeading state])
        output |= AP_HEADING;
    if ([channelMode state] && [channelAltitude state])
        output |= AP_ALTITUDE;
    if ([channelMode state] && [channelAirspeed state])
        output |= AP_AIRSPEED;
    if ([manualMode state])
        output |= AP_RCMANUAL;
    
    startstop[1] = 3;
	sendto(ctl_socket, &startstop[0], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
	sendto(ctl_socket, &startstop[1], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
    sendto(ctl_socket, &output, 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
    sendto(ctl_socket, &startstop[2], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
}

- (void)uploadMission:(NSMutableArray *)waypoints
{
    unsigned int sin_length,wp_count,i;
    unsigned char startstop[3] = {'A',2,'Z'};
    sin_length = sizeof(ctl_sockaddress);
    float   waypoint[5];

    // start byte
    sendto(ctl_socket, &startstop[0], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
    // command byte
    sendto(ctl_socket, &startstop[1], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
    // number of waypoints
    wp_count = [waypoints count];
    sendto(ctl_socket, &wp_count, 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
    
    // for each one, send the data as a struct of 4 floats
    for (i=0;i<wp_count;i++) {
        waypoint[0] = [[[waypoints objectAtIndex:i] objectForKey:@"y"]floatValue];
        waypoint[1] = [[[waypoints objectAtIndex:i] objectForKey:@"x"]floatValue];
        waypoint[2] = [[[waypoints objectAtIndex:i] objectForKey:@"alt"]floatValue];
        waypoint[3] = [[[waypoints objectAtIndex:i] objectForKey:@"airspeed"]floatValue];
        waypoint[4] = [[[waypoints objectAtIndex:i] objectForKey:@"uavindex"]floatValue];
        
        NSLog(@"Writing waypoint %d of %d: lat: %f lon: %f alt: %f spd: %f uav: %f\n",
            i,wp_count,
            waypoint[0],waypoint[1],waypoint[2],waypoint[3],waypoint[4]);
        
        sendto(ctl_socket, &waypoint, sizeof(waypoint), MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
    }
    sendto(ctl_socket, &startstop[2], 1, MSG_WAITALL, (struct sockaddr *)&ctl_sockaddress, sizeof(ctl_sockaddress));
} 

/*
 * Setup timer to update the OpenGL view.
 */
- (void) setupRenderTimer
{
   NSTimeInterval timeInterval = 1/15.0f;

   renderTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval
                             target:self
                             selector:@selector( updateGLView: )
                             userInfo:nil repeats:YES ] retain ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSEventTrackingRunLoopMode ];
   [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
                                  forMode:NSModalPanelRunLoopMode ];
}


/*
 * Called by the rendering timer.
 */
- (void) updateGLView:(NSTimer *)timer
{
	if( videoFeed != nil )
		[ videoFeed drawRect:[ videoFeed frame ] ];
}

- (IBAction)requestMapZoomIn:(id)sender
{
	[missionWindowController requestZoomIn: self];
}

- (IBAction)requestMapZoomOut:(id)sender
{
	[missionWindowController requestZoomOut: self];
}

- (float)ntohf:(float)source
{
	#ifdef __LITTLE_ENDIAN__
	float destination;
	char *sourcePointer,*destinationPointer;
	int i;
	
	sourcePointer = (char *)&source;
	destinationPointer = (char *)&destination;
	
	for(i=3;i>=0;i--)
		destinationPointer[3-i] = sourcePointer[i];
	return destination;
	#else
	return source;
	#endif
}

- (double)ntohd:(double)source
{
	#ifdef __LITTLE_ENDIAN__
	double destination;
	char *sourcePointer,*destinationPointer;
	int i;
	
	sourcePointer = (char *)&source;
	destinationPointer = (char *)&destination;
	
	for(i=7;i>=0;i--)
		destinationPointer[7-i] = sourcePointer[i];
		
	return destination;
	#else
	return source;
	#endif
}
@end
