/*
 *  rcrx.c 
 *  
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#include <sys/time.h>

#include "common.h"
#include "rcrx.h"
#include "aircraft.h"

/* manual deflections */
deflection_t global_rc_deflections;

/* pxarc devices and file descriptors */
const char *pxarc_dev_in = "/dev/opwm0";
int pxarc_fd_in;

void rcrx_init(void){
	struct timespec rcrx_ts;
	rcrx_ts.tv_sec = 0;
	rcrx_ts.tv_nsec = 10 * 10000000; /* 10 Hz */
    
    printf("Thread RCRX detached with id: %x\n", (unsigned int)pthread_self());
    
    pxarc_fd_in = open(pxarc_dev_in, O_RDONLY, 0);
    if (pxarc_fd_in < 0)
        perror("pxarc_fd_in open");
        
    while (1) {
        nanosleep(&rcrx_ts,NULL);
		rcrx_task();
	}
	
	pthread_exit(NULL);
}

void rcrx_task(void){
    unsigned short channels[4];
    
    int nr = read(pxarc_fd_in, channels, sizeof(channels));
    /*suppress unused warning for now*/
    nr++;nr--;
    
    /* scale raw PWM channel values to our internal Real set -1...1 */
    global_rc_deflections.aileron = (channels[RC_CHANNEL_AILERON] * 2.0f - 32768.0f) / 32768.0f;
    global_rc_deflections.elevator = (channels[RC_CHANNEL_ELEVATOR] * 2.0f - 32768.0f) / 32768.0f;
	global_rc_deflections.rudder = (channels[RC_CHANNEL_RUDDER] * 2.0f - 32768.0f) / 32768.0f;
    
    /* throttle is exception. goes from 0 to 1 */
	global_rc_deflections.throttle = channels[RC_CHANNEL_THROTTLE] / 65535.0f;
}
