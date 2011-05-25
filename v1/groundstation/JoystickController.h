#import <Cocoa/Cocoa.h>
#include "HID_Utilities_External.h"

#define AILERON_AXIS 0
#define ELEVATOR_AXIS 1
#define RUDDER_AXIS 2
#define THROTTLE_AXIS 3

@interface JoystickController : NSObject
{
	pRecDevice			selectedJoystick;
	pRecElement			axes[4],hatSwitch,buttons[7];
	int					axes_map[4];
}

- init;
- (SInt32)returnAxisValue:(int)theElement;
- (SInt32)returnHatswitchValue;
- (SInt32)returnButtonValue:(int)theButton;
- (void)remapAxis:(int)axisIndex toValue:(int)mapIndex;

@end
