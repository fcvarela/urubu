/*
 *  actuator.c
 *  
 *
 *  Created by Filipe Varela on 07/01/30.
 *  Copyright 2007 Filipe Varela. All rights reserved.
 *
 */

#include <unistd.h> 
#include <string.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <arpa/inet.h>

#include "actuator.h" 
#include "common.h"
#include "networkglue.h"
#include "sensor_acquisition.h"
#include "navigation.h"
#include "aircraft.h"

extern deflection_t global_ap_deflections; /* written by navigation task */
extern deflection_t global_manual_deflections; /* written by control task in telemetry */
extern deflection_t global_rc_deflections; /* from pxarc */
extern aircraft_values_t aircraft_values; /* from aircraft.c */
extern int pxarc_fd_out; /* pxarc_opwm device file descriptor */

/* NEED WATCHDOG FOR RC OR MANUAL DELTA FROM LAST COMMAND! IF EXPIRES -> REVERT TO FULLAUTO AND GO HOME
   CANNOT LET FLIGHT START WITHOUT A HOME WP AND HOME APPROACH PATH
*/
deflection_t final_deflections;

void actuate( void ){
	
	/* mission? */
	if(navigation_apgetmode(AP_WAYPOINT)) {
		memcpy(&final_deflections,&global_ap_deflections,sizeof(deflection_t));
        actuate_wrapper();
        return;
    }
    
    /* full rc manual */
    if(navigation_apgetmode(AP_RCMANUAL)) {
        memcpy(&final_deflections,&global_rc_deflections,sizeof(deflection_t));
        actuate_wrapper();
        return;
    }
    
    /* not mission nor full rc manual:
        each channel is either ap_assisted or manual from groundstation */
    
    /* ailerons/rudder */
	if(navigation_apgetmode(AP_HEADING)){
		final_deflections.aileron = global_ap_deflections.aileron;
		final_deflections.rudder = global_ap_deflections.rudder;
	}
	else{
		final_deflections.aileron = global_manual_deflections.aileron;
		final_deflections.rudder = global_manual_deflections.rudder;
	}
			
	/* elevator */
	if(navigation_apgetmode(AP_ALTITUDE))
		final_deflections.elevator = global_ap_deflections.elevator;
	else
		final_deflections.elevator = global_manual_deflections.elevator;
	
	/* throttle */
	if(navigation_apgetmode(AP_AIRSPEED))
		final_deflections.throttle = global_ap_deflections.throttle;
	else
		final_deflections.throttle = global_manual_deflections.throttle;
	
	actuate_wrapper();
}

void actuate_wrapper(void)
{
    if(SENSOR_BOARD == XPLANE_SENSOR)
        xplane_actuate();
    else
        servo_actuate();
}

void xplane_actuate(void){
	int	index;
	float value;
	unsigned char ctrl_packet[44];
    
	memset(&ctrl_packet, 0, sizeof(ctrl_packet));
	ctrl_packet[0] = 'D';
	ctrl_packet[1] = 'A';
	ctrl_packet[2] = 'T';
	ctrl_packet[3] = 'A';
	ctrl_packet[4] = 0;
	
	index = ntohl(9);
	memcpy(&ctrl_packet[5],&index,sizeof(index));
	
	value = ntohf(final_deflections.aileron);
	memcpy(&ctrl_packet[13],&value,sizeof(value));
	
	value = ntohf(final_deflections.elevator);
	memcpy(&ctrl_packet[9],&value,sizeof(value));
	
	value = ntohf(final_deflections.rudder);
	memcpy(&ctrl_packet[17],&value,sizeof(value));
	
	value = -999;
	memcpy(&ctrl_packet[21],&value,sizeof(value));
	memcpy(&ctrl_packet[25],&value,sizeof(value));
	memcpy(&ctrl_packet[29],&value,sizeof(value));
	memcpy(&ctrl_packet[33],&value,sizeof(value));
	memcpy(&ctrl_packet[37],&value,sizeof(value));
	
	network_write_xplane(&ctrl_packet,sizeof(ctrl_packet));
	
	/* NOW THROTTLE */
	index = ntohl(23);
	memcpy(&ctrl_packet[5],&index,sizeof(index));
	
	value = ntohf(final_deflections.throttle);
	memcpy(&ctrl_packet[9],&value,sizeof(value));
	memcpy(&ctrl_packet[13],&value,sizeof(value));
	memcpy(&ctrl_packet[17],&value,sizeof(value));
	memcpy(&ctrl_packet[21],&value,sizeof(value));
	memcpy(&ctrl_packet[25],&value,sizeof(value));
	memcpy(&ctrl_packet[29],&value,sizeof(value));
	memcpy(&ctrl_packet[33],&value,sizeof(value));
	memcpy(&ctrl_packet[37],&value,sizeof(value));
	
	network_write_xplane(&ctrl_packet,sizeof(ctrl_packet));
}

void servo_actuate(void){
    unsigned short channels[4];
    int nr;
    
    /* deflections are -1 to 1 and need to be 0 to 65535 */
    /* channels are mapped in aircraft.h */
    /* don't forget to scale 65535 to enforce max travels */
    
    channels[RC_CHANNEL_AILERON] = (final_deflections.aileron + 1) * (65535 * aircraft_values.aileron_scale_factor) / 2;
    channels[RC_CHANNEL_ELEVATOR] = (final_deflections.elevator + 1) * (65535 * aircraft_values.elevator_scale_factor) / 2;
    channels[RC_CHANNEL_RUDDER] = (final_deflections.rudder + 1) * (65535 * aircraft_values.rudder_scale_factor) / 2;
    
    /* exception goes 0 to 1 */
    channels[RC_CHANNEL_THROTTLE] = final_deflections.throttle * 65535;
    
    nr = write(pxarc_fd_out, channels, 4);
    nr++;nr--;
}
