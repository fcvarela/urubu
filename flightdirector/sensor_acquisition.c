/*
 *  sensor_acquisition.c
 *  
 *
 *  Created by Filipe Varela on 06/12/13.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 *
 *	must assume serialdaemon is already operational.
 *	send to udp port 1234 to serial out to sensorboard
 *	read from udp port 1234 to get sensor packet
 *
 *	operation: read from sensorboard. export data into global raw_sensor struct
 *			   ahrs.c will read raw_sensor and create attitude estimate
 *
*/

/* IMPORTANT: CODE HERE IS PREP'D FOR ADXRS150. TEMP CALIBRATION AND ADC SCALE VALUES DEPENDS ON GYRO */

#include <pthread.h>
#include <stdio.h>

#include "sensor_acquisition.h"

#include "robostix_acquisition.h"
#include "x-plane_acquisition.h"

/* global sensor struct */
sensor_t global_sensor;

/********************************* MAIN LOOP ********************************************************/
void sensor_start_listener( void ){
	printf("Thread SENSOR/AHRS detached with id: %x\n", (unsigned int)pthread_self());
	/* call the appropriate sensor initializer */
	switch(SENSOR_BOARD){
		case ROBOSTIX_SENSOR: robostix_start_listener(); break;
		case XPLANE_SENSOR: xplane_start_listener(); break;
	}
}
