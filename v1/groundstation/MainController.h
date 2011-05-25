//load attitude from udp stream?
#import <Cocoa/Cocoa.h>
#import <JoystickController.h>
#import <MissionWindowController.h>
#import <PreferencesWindowController.h>
#import <AutopilotWindowController.h>
#import "CSGCamera.h"
#import "MyHUDView.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@interface MainController : NSWindowController
{	
	//SLIDERS
	IBOutlet id xAxisSlider;
    IBOutlet id yAxisSlider;
    IBOutlet id zAxisSlider;
	IBOutlet id sliderSlider;
	IBOutlet id throttleTestSlider;
    
    //AP CHANNELS
    IBOutlet id desiredStateHeading;
    IBOutlet id desiredStateAltitude;
    IBOutlet id desiredStateAirspeed;
    
    //AP TAB
    IBOutlet id missionMode, channelMode, manualMode;
    IBOutlet id channelHeading, channelAltitude, channelAirspeed;
	
	//BUTTONS
	IBOutlet id hatswitch;
	IBOutlet id button1;
	IBOutlet id button2;
	IBOutlet id button3;
	IBOutlet id button4;
	IBOutlet id button5;
	IBOutlet id button6;
	IBOutlet id button7;
	
	IBOutlet MyHUDView *videoFeed;
	IBOutlet id	sliderInvertCheckbox;
	IBOutlet id mainWindow, aboutWindow;
    IBOutlet id selectedCraftPopup;
	
	JoystickController *theJoystick;
	NSTimer *joystickTimer,*renderTimer;
	MissionWindowController *missionWindowController;
	PreferencesWindowController *preferencesWindowController;
	AutopilotWindowController *autopilotWindowController;

	CSGCamera					*camera;
	
	/* next put this in joystick handler class */
	int	aileron,throttle,rudder,elevator;
	
	struct sockaddr_in tel_sockaddress;
	struct sockaddr_in ctl_sockaddress;
    struct sockaddr_in iph_sockaddress;
	int tel_socket,ctl_socket,iph_socket,selectedCraft;
	float packet[4][9];
	
	/* control mode... we need to clean this up later on */
	/* 0 = full auto. we just listen, 1 = direct joystick relay, 2 = assisted. we send desired course, etc */
	unsigned char control_mode; 
	unsigned char control_needs_send; /* 0 after we send, 1 after we change */
	float desired_state[4][3]; /* heading, altitude, airspeed */
}

- (void)awakeFromNib;
- (void)updateJoystickReadings:(id)Sender;
- (void)setupJoystickTimer;
- (void)dealloc;

- (IBAction)resetJoystickController:(id)sender;
- (IBAction)showMapWindow:(id)sender;
- (IBAction)showVideoWindow:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)showAutopilotWindow:(id)sender;

- (IBAction)requestMapZoomIn:(id)sender;
- (IBAction)requestMapZoomOut:(id)sender;

- (IBAction)openMissionFromMenu:(id)sender;
- (IBAction)saveMissionFromMenu:(id)sender;

- (IBAction)parseThrottleSlider:(id)sender;

- (void)gotVideoSetup:(id)sender;

- (void)remapAxis:(int)axisIndex toValue:(int)mapIndex;

- (void)preferencesDidChange;

- (float)ntohf:(float)source;
- (double)ntohd:(double)source;

- (IBAction)startSampling:(id)sender;
- (IBAction)stopSampling:(id)sender;
- (IBAction)updateSelectedCraft:(id)sender;
- (void)receiveTelemetryStream:(id)sender;

- (void) setupRenderTimer;
- (void) updateGLView:(NSTimer *)timer;
- (void) transmitControlStream;
- (void) transmitControlPacket;
- (void) setControlNeedsSend:(id)sender;

@end
