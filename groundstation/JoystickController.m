#import "JoystickController.h"
#include <Kernel/IOKit/hidsystem/IOHIDUsageTables.h>

@implementation JoystickController

- init
{
	int				i,foundDevices,numHIDDevices,elementCount;
	pRecElement		elRec;
	pRecDevice		deviceCandidate = NULL;
	int				axisIndex=-1;
	
	//initialize HID Device list
	HIDBuildDeviceList(kHIDPage_GenericDesktop, kHIDUsage_GD_Joystick);
	if(!HIDHaveDeviceList()){
	}
	
	numHIDDevices = HIDCountDevices();
	//initialize our counters
	i=0;
	foundDevices=0;
	deviceCandidate = HIDGetFirstDevice();
	
	while(i<numHIDDevices){
		if(deviceCandidate){
			//filter out all but joysticks
			if( deviceCandidate->usage==kHIDUsage_GD_Joystick){
				//store in list
				selectedJoystick = deviceCandidate;
				deviceCandidate = HIDGetNextDevice( deviceCandidate );
				foundDevices++;
			}
			i++;
		}
	}
	
	if(foundDevices==0)
		return( NULL );
	elementCount = HIDCountDeviceElements(selectedJoystick, kHIDElementTypeInput);
	i=0;
	elRec = HIDGetFirstDeviceElement(selectedJoystick,kHIDElementTypeInput);
	while(i<elementCount){
		if(elRec){
			if( elRec->usagePage==kHIDPage_GenericDesktop ){
				//deal with joystick axes and hatswitch
				if(elRec->usage >= 0x30 && elRec->usage <= 0x36){
					axisIndex++;
					axes[axisIndex] = elRec;
				}
				if(elRec->usage == kHIDUsage_GD_Hatswitch)
					hatSwitch = elRec;
			} else if( elRec->usagePage==kHIDPage_Button ){
				//deal with joystick buttons:
				//trigger + up/down left of thumb + up/down right of thump + 2 down buttons
				switch(elRec->usage){
					case 0x01 : buttons[0] = elRec; break;
					case 0x02 : buttons[1] = elRec; break;
					case 0x03 : buttons[2] = elRec; break;
					case 0x04 : buttons[3] = elRec; break;
					case 0x05 : buttons[4] = elRec; break;
					case 0x06 : buttons[5] = elRec; break;
					case 0x07 : buttons[6] = elRec; break;
				}
			}
			
			elRec = HIDGetNextDeviceElement(elRec,kHIDElementTypeInput);
			i++;
		}
		else{
		}
	}
	return( self );
}

- (SInt32)returnAxisValue:(int)theElement
{
	SInt32		rawValue;
	
	if(axes[axes_map[theElement]]){
		rawValue=HIDGetElementValue(selectedJoystick,axes[axes_map[theElement]]);
		return(HIDScaleValue(rawValue,axes[axes_map[theElement]]));
	}
	else
		return -1;
}

- (SInt32)returnHatswitchValue{
	if(hatSwitch)
		return HIDGetElementValue(selectedJoystick, hatSwitch);
	else
		return -1;
}

- (SInt32)returnButtonValue:(int)theButton{
	if(buttons[theButton])
		return HIDGetElementValue(selectedJoystick, buttons[theButton]);
	else
		return -1;
}

- (void)remapAxis:(int)axisIndex toValue:(int)mapIndex
{
	axes_map[mapIndex] = axisIndex;
}

@end
