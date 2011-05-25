//
//  untitled.m
//  testbed2
//
//  Created by Filipe Varela on 05/06/15.
//  Copyright 2005 Filipe Varela. All rights reserved.
//
    
#import "MissionWindowController.h"
#import "ToolbarCategory.h"

@implementation MissionWindowController

-(id)init
{
    self = [super initWithWindowNibName:@"MissionWindow"];
    return(self);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSString *titleString;
    
    int h_origin = [theMapView visibleRect].origin.x;
    int h_end = [theMapView visibleRect].origin.x + [theMapView visibleRect].size.width;
    int v_origin = [theMapView visibleRect].origin.y;
    int v_end = [theMapView visibleRect].origin.y + [theMapView visibleRect].size.height;
    
    NSPoint thePoint = [theMapView convertPoint: [theEvent locationInWindow] fromView: nil];
    float zoomLevel = [theMapView zoomLevel];
    
    if(thePoint.x >= h_origin && thePoint.x <= h_end && thePoint.y >= v_origin && thePoint.y <= v_end){
        NSPoint theGPSPoint = [theMapView gpsCoordinatesFromPoint:thePoint];
        //NSPoint theLocalPoint = [theMapView pointCoordinatesFromGps: theGPSPoint];
        titleString = [NSString stringWithFormat: @"Lat: %f Lon: %f Zoom: %f", theGPSPoint.y, theGPSPoint.x, zoomLevel];
        [theMapView setCursorPoint: thePoint];
        //titleString = [titleString stringByAppendingString: [NSString stringWithFormat: @" %f %f", theLocalPoint.x, theLocalPoint.y]];
        [[self window] setTitle: titleString];
    }
}

-(void)awakeFromNib
{
    [[self window] setDelegate: self];
    [[self window] setAcceptsMouseMovedEvents: YES];
    [self setupToolbar];
    theMission = [[Mission alloc] init];
    [theMapView setPoints: [theMission returnWaypoints]];
}

-(void)loadMission:(id)sender
{
    NSArray *fileTypes = [NSArray arrayWithObject:@"mission"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel beginSheetForDirectory:@"" file:nil types:fileTypes modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(openSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)openSheetDidEnd:(NSOpenPanel *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton) {
        NSString *aFile = [theSheet filename];
        //this will destroy the mission waypoints array and create a new one
        [theMission loadWaypointsFromFile: aFile];
        //therefore themapview loses the connection to mission's waypoint instance.
        //we need to re-connect them here.
        [theMapView setPoints: [theMission returnWaypoints]];
        [theMapView setBaseCoordinates: [theMission returnBaseCoordinates]];
        [theMapView setBackgroundImageData: [theMission returnBackgroundImageData]];
        //since themapview lost and regained a connection to an instance, we should redisplay it for sanity's sake
        [theMapView setNumberOfAircraft: [theMission returnNumberOfAircraft]];
        [theMapView setObservationStartPoint: [theMission returnObservationStartPoint]];
        [theMapView setObservationWidth: [theMission returnObservationWidth]];
        [theMapView setNeedsDisplay:YES];
    }
}

-(void)resetMission:(id)sender
{
    Mission *newMission = [[Mission alloc] init];
    [newMission retain];
    [theMission release];
    theMission = newMission;
    [theMapView setPoints: [theMission returnWaypoints]];
    [theMapView setBackgroundImageData: nil];
}

-(void)saveMission:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setRequiredFileType:@"mission"];
    [savePanel beginSheetForDirectory:@"" file:@"" modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)saveSheetDidEnd:(NSSavePanel *)theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton) {
        //create the dictionary that will contain the mission and waypoint data
        //we need to set mission's image to the view image so the save stores it correctly.
        [theMission setBackgroundImageData: [theMapView returnImageData]];
        [theMission saveWaypointsAs:[theSheet filename]];
    }
}

- (void)showPropertiesPanel:(id)sender
{
    NSDictionary *theCoords = [theMission returnBaseCoordinates];
    
    [startLatitudeField setStringValue: [NSString localizedStringWithFormat: @"%3.6f", [[theCoords valueForKey:@"startLatitude"] floatValue]]];
    [endLatitudeField setStringValue: [NSString localizedStringWithFormat: @"%3.6f", [[theCoords valueForKey:@"endLatitude"] floatValue]]];
    [startLongitudeField setStringValue: [NSString localizedStringWithFormat: @"%3.6f", [[theCoords valueForKey:@"startLongitude"] floatValue]]];
    [endLongitudeField setStringValue: [NSString localizedStringWithFormat: @"%3.6f", [[theCoords valueForKey:@"endLongitude"] floatValue]]];
    [numberOfAircraftField setStringValue: [NSString localizedStringWithFormat: @"%d", [[theMission returnNumberOfAircraft] intValue]]];
    [observationStartField setStringValue: [NSString localizedStringWithFormat: @"%d", [[theMission returnObservationStartPoint] intValue]]];
    [observationWidthField setStringValue: [NSString localizedStringWithFormat: @"%d", [[theMission returnObservationWidth] intValue]]];
    [cameraApertureField setStringValue: [NSString localizedStringWithFormat: @"%d", [[theMission returnCameraAperture] intValue]]];
    
    [NSApp beginSheet: propertiesPanel modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(propertiesSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)closePropertiesPanel:(id)sender
{
    [NSApp endSheet: propertiesPanel];
}

- (void)propertiesSheetDidEnd:theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [theSheet orderOut:self];
    
    NSMutableDictionary *baseCoordinates = [[NSMutableDictionary alloc] init];
    [baseCoordinates setObject: [NSNumber numberWithFloat: [startLatitudeField floatValue]] forKey:@"startLatitude"];
    [baseCoordinates setObject: [NSNumber numberWithFloat: [endLatitudeField floatValue]] forKey:@"endLatitude"];
    [baseCoordinates setObject: [NSNumber numberWithFloat: [startLongitudeField floatValue]] forKey:@"startLongitude"];
    [baseCoordinates setObject: [NSNumber numberWithFloat: [endLongitudeField floatValue]] forKey:@"endLongitude"];
    
    [theMission setBaseCoordinates: baseCoordinates];
    [theMapView setBaseCoordinates: baseCoordinates];
    
    // to mission
    [theMission setNumberOfAircraft:[NSNumber numberWithInt: [numberOfAircraftField intValue]]];
    [theMission setObservationStartPoint:[NSNumber numberWithInt: [observationStartField intValue]]];
    [theMission setObservationWidth:[NSNumber numberWithInt: [observationWidthField intValue]]];
    [theMission setCameraAperture:[NSNumber numberWithInt: [cameraApertureField intValue]]];
    
    // to map
    [theMapView setNumberOfAircraft:[NSNumber numberWithInt: [numberOfAircraftField intValue]]];
    [theMapView setObservationStartPoint:[NSNumber numberWithInt: [observationStartField intValue]]];
    [theMapView setObservationWidth:[NSNumber numberWithInt: [observationWidthField intValue]]];
    [theMapView setCameraAperture:[NSNumber numberWithInt: [cameraApertureField intValue]]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return YES;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    int toolbarHeight;
    
    // get the y-origin of the scroll view for use in computing newHeight
    int svOffset = [[[theMapView superview] superview] frame].origin.y;

    NSSize viewSize = [theMapView frame].size;
    float newHeight = viewSize.height + svOffset;
    float newWidth = viewSize.width;

    NSRect stdFrame = [NSWindow contentRectForFrameRect:[sender frame] styleMask:[sender styleMask]];
    toolbarHeight = NSHeight([sender frame]) - NSHeight([[sender contentView] frame])-22;
    
    stdFrame.origin.y += stdFrame.size.height;
    stdFrame.origin.y -= newHeight + toolbarHeight;
    stdFrame.size.height = newHeight + toolbarHeight;
    stdFrame.size.width = newWidth;
    
    stdFrame = [NSWindow frameRectForContentRect:stdFrame styleMask:[sender styleMask]];
    
    return stdFrame;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
    int    newWidth,newHeight;
    int    scrollWidth,scrollHeight;
    
    if( [theScrollView documentVisibleRect].size.width < [theMapView frame].size.width )
        scrollHeight = 15;
    else
        scrollHeight = 0;
        
    if( [theScrollView documentVisibleRect].size.height < [theMapView frame].size.height )
        scrollWidth = 15;
    else
        scrollWidth = 0;
    
    newWidth = 0; newHeight=0;
    NSRect maxRect = [self windowWillUseStandardFrame: sender defaultFrame:NSMakeRect(0,0,1,1)];
    
    //por +scrollwidth na condição if
    if( proposedFrameSize.width >= maxRect.size.width)
        newWidth = maxRect.size.width+scrollWidth;
    else
        newWidth = proposedFrameSize.width;
    
    if( proposedFrameSize.height >= maxRect.size.height)
        newHeight = maxRect.size.height+scrollHeight;
    else
        newHeight = proposedFrameSize.height;
    
    return NSMakeSize( newWidth, newHeight );
}

- (void)setDelegate:(id)sender
{
    _delegate = sender;
}

- (void)requestZoomIn:(id)sender
{
    [theMapView zoomIn:sender];
}

- (void)requestZoomOut:(id)sender
{
    [theMapView zoomOut:sender];
}

- (void)uploadMission:(id)sender
{
    // convert all points to gps
    if (_delegate)
        [_delegate uploadMission: [theMapView GPSPoints]];
}

/* relay aircraft point to window */
- (void)setAircraftPoint:(NSPoint)thePoint heading:(float)newHeading desiredHeading:(float)newDesiredHeading forAddress:(int)uav
{
    [theMapView setAircraftPoint: thePoint heading:newHeading desiredHeading: newDesiredHeading forAddress: uav];
}

- (void)requestRedraw
{
    [theMapView setNeedsDisplay: YES];
}

@end
