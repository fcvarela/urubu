/*
 *  ahrs_qekf.c
 *  
 *
 *  Created by Filipe Varela on 08/04/07.
 *  Copyright 2008 Filipe Varela. All rights reserved.
 *
 */

#include <stdio.h>
#include <string.h> /* memcpy */
#include <pthread.h>

/* pahrs structure data definition */
#include "ahrs_qekf.h"
#include "ahrs_quat_fast_ekf.h"
/* needed for sensor_t struct definition */
#include "sensor_acquisition.h"
/* common precalculated conversions */
#include "common.h"

/* where we'll get data from */
extern sensor_t global_sensor;

pahrs_t local_pahrs, global_pahrs;
pthread_mutex_t global_pahrs_mutex;

/************************ INIT CODE ***************************************/
void pahrs_init( void ) {
	
	/* init mutex */
	pthread_mutex_init(&global_pahrs_mutex, NULL);
	
	afe_init(global_sensor.c_heading, global_sensor.i_accels, global_sensor.i_rates);
}


void pahrs_process_filter( void ) {
    afe_predict(global_sensor.i_rates);
    afe_update_phi(global_sensor.i_accels);
    afe_update_theta(global_sensor.i_accels);
    afe_update_psi(global_sensor.c_heading);
	
    local_pahrs.angles[0] = afe_phi;
    local_pahrs.angles[1] = afe_theta;
    local_pahrs.angles[2] = afe_psi;
    
    local_pahrs.rates[0] = afe_p;
    local_pahrs.rates[1] = afe_q;
    local_pahrs.rates[2] = afe_r;
    
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
