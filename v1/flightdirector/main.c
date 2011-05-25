/*
 *  main.c
 *  
 *
 *  Created by Filipe Varela on 06/12/13.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 *	operation: 
 *		Sensor thread.
 *			Will read sensor output and call filtering routines
 *			No need to segregate filtering from acquisition in separate threads
 *			Because there's no point in either executing without the other
 *		
 *		Navigation outer-loop:
 *			Manual?
 *				Getting rc packets? Export them as actuator values
 *				Not? Go failsafe
 *				
 *			Auto?
 *				Getting sensor packets? Do navigation task
 *				Not? Go failsafe
 *		
 *		Navigation thread.
 *			Will read filtered output and process navigation pid loops
 *			Exports actuator values for all moving surfaces/motors
 *			Should acquisition/filtering halt (hardware/software error), detect
 *			rapid progression in dt (which is reset at every sensor output).
 *			Define max dt threshold to enter failsafe mode
 *			
 *			Failsafe: Ignore flight plan and define new desired position and attitude to
 *			safe values, ie, land at first oportunity. Set engine to feedback at minimum
 *			above-stall speed and vspeed to safe descent. Define target heading as current
 *			This should make us glide safely to target. We could also fast descent
 *			(if too high) while circling (no gps so define roll and maintain it) until
 *			a lower altitude and then do zero roll glide.
 *			
 *		Actuation thread
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <signal.h>
#include <strings.h>

#include "ahrs_qekf.h"
#include "sensor_acquisition.h"
#include "networkglue.h"
#include "telemetry.h"
#include "navigation.h"
#include "control.h"
#include "rcrx.h"

pthread_t pahrs_thread,navigation_thread,telemetry_thread,control_thread,rcrx_thread;

extern void sensor_start_listener( void );
static void signal_handler_sigterm( void );

unsigned char g_quit = 0;
char * GROUNDSTATION_IP_ADDRESS;
int URUBU_ADDRESS;

int main(int argc, char *argv[]) {
	int					retval;
	pthread_attr_t		attr;
	
    if (argc < 3) {
        printf("Usage: %s <groundstation ip> <local_address>\nExample: flightdirector 127.0.0.1 0\n", argv[0]);
        return 1;
    }
    else {
        GROUNDSTATION_IP_ADDRESS = argv[1];
        printf("Setting groundstation address to: %s\n", GROUNDSTATION_IP_ADDRESS);
        
        URUBU_ADDRESS = atoi(argv[2]);
        printf("Setting URUBU address to: %d\n", URUBU_ADDRESS);
    }
    
	printf("\nSTARTED (%d) with main thread id: %x\n\n", argc, (unsigned int)pthread_self());
	printf("Configuring threads\n");
	
	/* CONFIG ATTRIBS AND SCHEDULING PARAMETERS */
	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
	pthread_attr_setinheritsched(&attr,PTHREAD_EXPLICIT_SCHED);
	pthread_attr_setschedpolicy(&attr, SCHED_OTHER);
	
	printf("Configuring sockets\n");
	if( (retval = network_make_sockets()) < 0 ){
		perror("network_make_sockets");
		return -1;
	}
	
	printf("\nDetaching threads\n");
	/* detach sensor/filter thread */
	if( (retval = pthread_create(&pahrs_thread, &attr, (void *)&sensor_start_listener, NULL)) < 0){
		perror("pthread_create ahrs");
		return -1;
	}
	
	/* detach telemetry thread. works with serialdaemon */
	if( (retval = pthread_create(&telemetry_thread, &attr, (void *)&telemetry_init, NULL)) < 0){
		perror("pthread_create telemetry");
		return -1;
	}
	
	/* detach control thread */
	if( (retval = pthread_create(&control_thread, &attr, (void *)&control_init, NULL)) < 0){
		perror("pthread_create control");
		return -1;
	}
    
    /* detach rcrx (radio control reader) thread */
    if( (retval = pthread_create(&rcrx_thread, &attr, (void *)&rcrx_init, NULL)) < 0){
        perror("pthread_create rcrx");
        return -1;
    }
	
	/* detatch navigation thread. calculates deflections in 0-1.
		actuator maps that to servo values/x-plane values */
	if( (retval = pthread_create(&navigation_thread, &attr, (void *)&navigation_init, NULL)) < 0){
		perror("pthread_create navigation");
		return -1;
	}
		
	/* callback for sigterm */
	signal(SIGINT, (void *)signal_handler_sigterm);
	
	while(!g_quit){
		/* this would be a nice place to test ahrs/sensor halts and trigger a failsafe.
		   correction: failsafe + integrity checks need a separate thread.
		   this will only be used for curses */
		
		/* verify thread heartbeats. anyone not reporting for least 1 sec?
		   kill and relaunch */
		
		/* do a sleep to get updates at 10Hz */
		usleep(100000);
	}
		
	printf("\nWill send quit signals to threads...\n");
	pthread_kill(control_thread, SIGTERM);
	pthread_kill(telemetry_thread, SIGTERM);
	pthread_kill(navigation_thread, SIGTERM);
	pthread_kill(pahrs_thread, SIGTERM);
	
	return 0;
}

static void signal_handler_sigterm (void ) {
	g_quit = 1;
}
