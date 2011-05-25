#import "PreferencesWindowController.h"
#import "preferencesWindowToolbar.h"
#import "MainController.h"

@implementation PreferencesWindowController

-(id)init
{
	self=[super initWithWindowNibName:@"preferences"];
	return(self);
}

- (void)setDelegate:(id)sender
{
	delegate = sender;
}

- (id)delegate
{
	return delegate;
}

- (void)awakeFromNib
{
	//load preferences
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	[gpsCheck setIntValue:[defs integerForKey:@"gpsCheck"]];
	[groundSpeedCheck setIntValue:[defs integerForKey:@"groundSpeedCheck"]];
	[airspeedCheck setIntValue:[defs integerForKey:@"airspeedCheck"]];
	[inertialCheck setIntValue:[defs integerForKey:@"inertialCheck"]];
	[fpsCheck setIntValue:[defs integerForKey:@"fpsCheck"]];
	[dateTimeCheck setIntValue:[defs integerForKey:@"dateTimeCheck"]];
	[plotRouteMenu selectItemAtIndex:[defs integerForKey:@"plotRouteMenu"]];
	
	if([defs dataForKey:@"routePlotColor"]){
		NSColor *routePlotColorValue = [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routePlotColor"]];
		[routePlotColor setColor:routePlotColorValue];
	}
	if([defs dataForKey:@"routeLabelColor"]){
		NSColor *routeLabelColorValue = [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routeLabelColor"]];
		[routeLabelColor setColor:routeLabelColorValue];
    }
	if([defs dataForKey:@"apIndicatorColor"]){
		NSColor *apIndicatorColorValue = [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"apIndicatorColor"]];
		[apIndicatorColor setColor:apIndicatorColorValue];
    }
    if([defs dataForKey:@"overlayHUDColor"]){
        NSColor *overlayHUDColorValue = [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"overlayHUDColor"]];
		[overlayHUDColor setColor:overlayHUDColorValue];
    }
    if([defs dataForKey:@"overlayTextColor"]){
        NSColor *overlayTextColorValue = [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"overlayTextColor"]];
		[overlayTextColor setColor:overlayTextColorValue];
	}
	
	[self setupToolbar];
	[[self window] center];

	//registar para receber notificação de fecho de janela
	//permite gravar preferences
	[[self window] setDelegate: self];
	
	mapPrefsViewSize = [mapPrefsView frame].size;
	mapPrefsViewFrame = [mapPrefsView frame];
	videoPrefsViewSize = [videoPrefsView frame].size;
	videoPrefsViewFrame = [videoPrefsView frame];
	joystickPrefsViewSize = [joystickPrefsView frame].size;
	joystickPrefsViewFrame = [joystickPrefsView frame];
	
	[self showMapPrefsView:nil];
	
	blankView = [[NSView alloc] init];
	
	//make sure we get the joystick menu events
	[[controllerMapsMenuPopup menu] setDelegate: self];
	[[controllerAxesMenuPopup menu] setDelegate: self];
}

- (IBAction)gotVideoSetup:(id)sender
{
    if([self delegate])
		[[self delegate] gotVideoSetup:self];
}

- (IBAction)gotMenuChange:(id)sender
{	
	//get number from menuitemstring
	int selectedAxis =[controllerAxesMenuPopup indexOfItem: [controllerAxesMenuPopup selectedItem]];
	int selectedMap = [controllerMapsMenuPopup indexOfItem: [controllerMapsMenuPopup selectedItem]];
	
	if([self delegate])
		[[self delegate] remapAxis: selectedAxis toValue: selectedMap];
	else{
		
	}
}
		

- (void)resizeWindowToSize:(NSSize)newSize
{	
	NSRect aFrame;
    float newHeight = newSize.height;
	int toolbarHeight = 0;
	
	// CALCULAR ALTURA DA TOOLBAR
	NSToolbar *toolbar = [[self window] toolbar];
	if(toolbar && [toolbar isVisible]){
		NSRect windowFrame = [NSWindow contentRectForFrameRect:[[self window] frame] styleMask:[[self window] styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[[self window] contentView] frame]);
	}
	
	// CALCULAR NOVA FRAME
    aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] styleMask:[[self window] styleMask]];
    
    aFrame.origin.y += aFrame.size.height;
    aFrame.origin.y -= newHeight + toolbarHeight;
    aFrame.size.height = newHeight + toolbarHeight;
	
	[contentView setFrame: NSMakeRect(
		abs(aFrame.size.width/2)-abs(newSize.width/2),[contentView frame].origin.y,newSize.width,[contentView frame].size.height)
	];
	
	aFrame = [NSWindow frameRectForContentRect:aFrame styleMask:[[self window] styleMask]];
	
    [[self window] setFrame:aFrame display:YES animate:YES];
}

- (IBAction)showMapPrefsView:(id)sender
{
	[contentView setContentView: blankView];
	[self resizeWindowToSize: mapPrefsViewSize];
	[contentView setContentView:mapPrefsView];
    
	NSToolbar *toolbar = [[self window] toolbar];
	[toolbar setSelectedItemIdentifier:@"Mission"];
}

- (IBAction)showVideoPrefsView:(id)sender
{	
	[contentView setContentView: blankView];
	[self resizeWindowToSize: videoPrefsViewSize];
	[contentView setContentView:videoPrefsView];
}

- (IBAction)showJoystickPrefsView:(id)sender
{	
	[contentView setContentView: blankView];
	[self resizeWindowToSize: joystickPrefsViewSize];
	[contentView setContentView: joystickPrefsView];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	NSData *routeColorData = [NSArchiver archivedDataWithRootObject:[routePlotColor color]];
	NSData *routeLabelData = [NSArchiver archivedDataWithRootObject:[routeLabelColor color]];
	NSData *apIndicatorColorData = [NSArchiver archivedDataWithRootObject:[apIndicatorColor color]];
	NSData *overlayTextColorData = [NSArchiver archivedDataWithRootObject:[overlayTextColor color]];
    NSData *overlayHUDColorData = [NSArchiver archivedDataWithRootObject:[overlayHUDColor color]];
	
	[defs setObject:routeColorData forKey:@"routePlotColor"];
	[defs setObject:routeLabelData forKey:@"routeLabelColor"];
	[defs setObject:apIndicatorColorData forKey:@"apIndicatorColor"];
	[defs setObject:overlayTextColorData forKey:@"overlayTextColor"];
    [defs setObject:overlayHUDColorData forKey:@"overlayHUDColor"];
	
	[defs setInteger:[gpsCheck intValue] forKey:@"gpsCheck"];
	[defs setInteger:[groundSpeedCheck intValue] forKey:@"groundSpeedCheck"];
	[defs setInteger:[airspeedCheck intValue] forKey:@"airspeedCheck"];
	[defs setInteger:[inertialCheck intValue] forKey:@"inertialCheck"];
	[defs setInteger:[fpsCheck intValue] forKey:@"fpsCheck"];
	[defs setInteger:[dateTimeCheck intValue] forKey:@"dateTimeCheck"];
	[defs setInteger:[plotRouteMenu indexOfSelectedItem] forKey:@"plotRouteMenu"];
    
    if([self delegate])
		[(MainController *)[self delegate] preferencesDidChange];
}

- (void)replaceControllerAxesMenu:(NSMenu *)newMenu
{
	[controllerAxesMenuPopup setMenu: newMenu];
}

@end
