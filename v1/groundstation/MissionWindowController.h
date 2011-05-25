//
//  untitled.h
//  testbed2
//
//  Created by Filipe Varela on 05/06/15.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Mission.h>
#import <MapView.h>


@interface MissionWindowController : NSWindowController {
	Mission			*theMission;
	IBOutlet		id theMapView;
	IBOutlet		id theScrollView;
	IBOutlet		id propertiesPanel;
	
	IBOutlet		id startLatitudeField;
	IBOutlet		id endLatitudeField;
	IBOutlet		id startLongitudeField;
	IBOutlet		id endLongitudeField;
    IBOutlet        id numberOfAircraftField;
    IBOutlet        id observationStartField;
    IBOutlet        id observationWidthField;
    IBOutlet        id cameraApertureField;
    id              _delegate;
	
}

-(IBAction)closePropertiesPanel:(id)sender;

//MISSION LOADING AND SAVING
-(void)loadMission:(id)sender;
-(void)saveMission:(id)sender;

- (void)requestZoomIn:(id)sender;
- (void)requestZoomOut:(id)sender;

- (void)setAircraftPoint:(NSPoint)thePoint heading:(float)newHeading desiredHeading:(float)newDesiredHeading forAddress:(int)uav;
- (void)requestRedraw;
- (void)setDelegate:(id)sender;
@end
