/*
 *  ahrs.c
 *  
 *
 *  Created by Filipe Varela on 06/12/13.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 *	operation: use timer to sample global sensor data
 *			   and create attitude estimate in global_attitude;
 *
 *	important: accelerometers are centered in acquisition so no need to
 *			   do it here.
 *
 *  additional credits: quaternion integrator and quat2euler conversion
 *						completely based on <Rabih Hana>'s pseudo-code.
 *						still preliminary code. doesn't work so disable USE_QUATS
 *
 */

#include <math.h>
#include <stdio.h>
#include <string.h> /* memcpy */
#include <pthread.h>

/* pahrs structure data definition */
#include "ahrs.h"

/* try mp's rewrite of tilt.c */
#include "tilt.h"
tilt tilt_states[3];

/* global pahrs struct
	exp: local is used on the sensor and ahrs modules. same thread, no locks
	     at end of filter, lock global mutex, copy local to global, unlock
*/
pahrs_t local_pahrs, global_pahrs;
pthread_mutex_t global_pahrs_mutex;

/* needed for sensor_t struct definition */
#include "sensor_acquisition.h"

/* where we'll get data from */
extern sensor_t global_sensor;

/* common precalculated conversions */
#include "common.h"

/* accelerometer bias estimate (updated in kalman_update) */
float angle_reference_from_accels[3] = {0.0,0.0,0.0};

/************************ INIT CODE ***************************************/
void pahrs_init( void ){
	int i;
	
	/* init mutex */
	pthread_mutex_init(&global_pahrs_mutex, NULL);
	
	for(i=0;i<3;i++){
		tilt_init(&tilt_states[i], 0.0998, 0.3, 0.003, 0.001);
	}
}

/************************ SETUP MAIN LOOP ***********************************/
void pahrs_process_filter( void ){
	int i;
	
	/* attitude: */
	pahrs_accel_to_angle();
	
	for(i=0;i<3;i++){
		tilt_set_dt(&tilt_states[i], global_sensor.dt); /* required... keeps changing */
		tilt_state_update(&tilt_states[i], global_sensor.i_rates[i]);
		tilt_kalman_update(&tilt_states[i], angle_reference_from_accels[i]);
		local_pahrs.angles[i] = tilt_get_angle(&tilt_states[i]);
		local_pahrs.rates[i] = tilt_get_rate(&tilt_states[i]);
	}
	
	/* copy other sensor data */
	local_pahrs.latitude = global_sensor.g_latitude;
	local_pahrs.longitude = global_sensor.g_longitude;
	local_pahrs.g_altitude = global_sensor.g_altitude;
	local_pahrs.u_altitude = global_sensor.u_altitude;
	
	/* copy to global */
	pthread_mutex_lock(&global_pahrs_mutex);
	memcpy(&global_pahrs, &local_pahrs, sizeof(pahrs_t));
	pthread_mutex_unlock(&global_pahrs_mutex);
}

/*************************** ANGLE REFERENCE FROM ACCELEROMETERS **************/
void pahrs_accel_to_angle( void ){
	float g = sqrt(
		global_sensor.i_accels[0]*global_sensor.i_accels[0]+
		global_sensor.i_accels[1]*global_sensor.i_accels[1]+
		global_sensor.i_accels[2]*global_sensor.i_accels[2]);
		
	angle_reference_from_accels[0] = -asin(global_sensor.i_accels[0] / g);
	angle_reference_from_accels[1] = asin(global_sensor.i_accels[1] / g);
	angle_reference_from_accels[2] = global_sensor.c_heading;
}
