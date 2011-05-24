#import "AutopilotWindowController.h"

@implementation AutopilotWindowController

- (id) init
{
	self = [super initWithWindowNibName:@"AutopilotWindow"];
	if (self != nil) {}
	
	return self;
}

- (IBAction)transmit:(id)sender
{
	NSLog(@"Will send");
	NSLog(@"_throttle_i is %f\n", _throttle_i);
}

// accessors for bindings (not in interface)
- (double)roll_p { return _roll_p; }
- (double)roll_i { return _roll_i; }
- (double)roll_d { return _roll_d; }
- (double)pitch_p { return _pitch_p; }
- (double)pitch_i { return _pitch_i; }
- (double)pitch_d { return _pitch_d; }
- (double)throttle_p { return _throttle_p; }
- (double)throttle_i { return _throttle_i; }
- (double)throttle_d { return _throttle_d; }

@end
