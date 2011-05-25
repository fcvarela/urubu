/* AutopilotWindowController */

#import <Cocoa/Cocoa.h>

@interface AutopilotWindowController : NSWindowController
{
	double _roll_p, _roll_i, _roll_d;
	double _pitch_p, _pitch_i, _pitch_d;
	double _throttle_p, _throttle_i, _throttle_d;
}

- (IBAction)transmit:(id)sender;

@end
