/*
 *  control.c 
 *  
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/time.h>
#include <signal.h>
#include <pthread.h>
#include <arpa/inet.h>

#include "navigation.h"
#include "ahrs_qekf.h"
#include "control.h"
#include "common.h"
#include "telemetry.h"
#include "networkglue.h"
#include "aircraft.h"
#include "actuator.h"


/* individual ap channels */
extern ap_packet_t ap_channels;

/* manual deflections */
deflection_t global_manual_deflections;

/* pxarc devices and file descriptors */
const char *pxarc_dev_out = "/dev/opwm0";
int pxarc_fd_out;

void control_init(void){
	printf("Thread CONTROL detached with id: %x\n", (unsigned int)pthread_self());
        
    pxarc_fd_out = open(pxarc_dev_out, O_WRONLY, 0);
    if (pxarc_fd_out < 0)
        perror("pxarc_fd_out open");
        
    while (1) {
        /* printf("Control[%x]: Will run control task\n", (unsigned int)pthread_self()); */
		control_task();
	}
	
	pthread_exit(NULL);
}

/* not triggered by overflow. this task is locking and waits for groundstation commands */
void control_task(void){
	unsigned char aChar;
	int res;
	float deflections[4], desired_state[3];
	
	/* receive deflections from groundstation. are we manual/assisted/automated? */
    /* packet format [char A][0-99][packet specific payload][char Z] */
	res = network_read_control(&aChar, 1);
	if(aChar == 'A'){
		network_read_control(&aChar,1);
		switch(aChar){
			case 0: res = network_read_control(&deflections, sizeof(deflections)); break;
			case 1: res = network_read_control(&desired_state, sizeof(desired_state)); break;
            case 2: res = network_read_mission(); break;
            case 3: 
                /* clear navigation mode. unset all ones */
                navigation_apunsetmode(255);
                
                /* read mode bitfield flag mask */
                res = network_read_control(&aChar, 1);
                
                /* set it */
                navigation_apsetmode(aChar);
            break;
		}
		res = network_read_control(&aChar, 1);
				
		if(aChar == 'Z'){
			global_manual_deflections.aileron = deflections[0];
			global_manual_deflections.elevator = deflections[1];
			global_manual_deflections.rudder = deflections[2];
			global_manual_deflections.throttle = deflections[3];
			
			ap_channels.heading = desired_state[0]*d2r;
			ap_channels.altitude = desired_state[1];
			ap_channels.airspeed = desired_state[2];
		}
	}
}
