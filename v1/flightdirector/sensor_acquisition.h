/*
 *  sensor_acquisition.h
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
 *	operation: read from sensorboard (sparkfun 6dof v1 + other sensors).
			   export data into global raw_sensor struct
 *			   ahrs.c will read raw_sensor and create attitude estimate
 *
*/

#ifndef SENSORACQUISITION_H
#define SENSORACQUISITION_H

/* sensors available for input */
#define ROBOSTIX_SENSOR 0
#define XPLANE_SENSOR 1

/* which are we using */
/* real sensor #define SENSOR_BOARD ROBOSTIX_SENSOR */
/* x-plane simulation */
#define SENSOR_BOARD XPLANE_SENSOR

#include <sys/time.h>

/* where we store all sensor data */
/* g_ gps, u_ ultrasound, c_ compass, p_ pressure, i_ inertial*/

typedef struct{
	double dt; /* user needs to fill in */
	float g_time;
	int	g_satelites;
	float g_latitude;
	float g_longitude;
	float g_altitude;
	double u_altitude;
	double c_heading;
	double p_dynamic;
	double p_static;
	double i_accels[3];
	double i_rates[3];
	double i_battery;
} sensor_t;

/********************************* PROTOTYPES ******************/
void sensor_start_listener(void);

#endif
