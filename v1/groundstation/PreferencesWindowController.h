/* PreferencesWindowController */

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController
{
    //Prefs outlets
	IBOutlet id airspeedCheck;
    IBOutlet id dateTimeCheck;
    IBOutlet id fpsCheck;
    IBOutlet id gpsCheck;
    IBOutlet id groundSpeedCheck;
    IBOutlet id inertialCheck;
    IBOutlet id plotRouteMenu;
    IBOutlet id routePlotColor;
	IBOutlet id routeLabelColor;
	IBOutlet id apIndicatorColor;
	IBOutlet id overlayTextColor;
    IBOutlet id overlayHUDColor;
	IBOutlet id controllerAxesMenuPopup;
	IBOutlet id controllerMapsMenuPopup;
	
	//Base values.
    NSSize		mapPrefsViewSize,videoPrefsViewSize, joystickPrefsViewSize;
	NSRect		mapPrefsViewFrame,videoPrefsViewFrame, joystickPrefsViewFrame;
	
	//Op outlets
	IBOutlet id		mapPrefsView;
    IBOutlet id		videoPrefsView;
	IBOutlet id		joystickPrefsView;
	IBOutlet NSBox	*contentView;
	
	//Blank view for resizes
	NSView				*blankView;
	id					delegate;
}

- (IBAction)showMapPrefsView:(id)sender;
- (IBAction)showVideoPrefsView:(id)sender;
- (IBAction)showJoystickPrefsView:(id)sender;
- (IBAction)gotMenuChange:(id)sender;
- (IBAction)gotVideoSetup:(id)sender;

- (void)replaceControllerAxesMenu:(NSMenu *)newMenu;
- (void)setDelegate:(id)sender;

- (id)delegate;

@end
