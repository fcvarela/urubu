/*
 *  navigation.c
 *  
 *
 *  Created by Filipe Varela on 06/12/18.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

/* IMPORTANT: NEED TO APPEND SCRIPT TO EACH WAYPOINT IE
	WP0 - SCRIPT = TAKEOFF: MOVE (ON GROUND) TO WP0, POINT TO WP1, FULL THROTTLE, CLIMB TO TGT ALT (WP1)
	ALWAYS CONSIDER WP0 MUST BE GROUND NAVIGATED TO
	WP(SIZEOF WP[]-2) - LAND: DESCEND TO THIS ALT, POINT TO FINAL WAYPOINT, CUT THROTTLE AND MAINTAIN phi,theta,psi
	GOT AIRBRAKES? USE THEM IF AIRSPEED DOES NOT CUT FAST ENOUGH 
*/

#include <stdio.h>
#include <unistd.h>
#include <math.h>
#include <sys/time.h>
#include <signal.h>
#include <pthread.h>
#include <string.h>

#include "navigation.h"
#include "common.h"
#include "ahrs_qekf.h"
#include "aircraft.h"
#include "pid_controller.h"
#include "mission.h"

#define PROPORTIONAL 0
#define INTEGRAL 1
#define DERIVATIVE 2

extern int URUBU_ADDRESS;
extern pahrs_t global_pahrs;
extern pthread_mutex_t global_pahrs_mutex;
pahrs_t pahrs_copy_navigation;

extern aircraft_values_t aircraft_values;
extern mission_t *mission;

/* autopilot mode */
unsigned char autopilot_mode; /* bit field. */

/* single channel ap packet */
ap_packet_t ap_channels;

/* time derivative */
float navigation_dt = 0.1;

/* export global deflections for actuator module */
deflection_t global_ap_deflections;

/* PID CONTROLLER */
pid_controller altitude_pid_controller, heading_pid_controller, heading_r_pid_controller, airspeed_pid_controller;

/******************* initialize timer ******************/
void navigation_init(void){
	struct timespec navigation_ts;
	navigation_ts.tv_sec = 0;
	navigation_ts.tv_nsec = 10 * 10000000;
	
	printf("Thread NAVIGATION detached with id: %x\n", (unsigned int)pthread_self());
	
	sleep(1);
	
	navigation_apsetmode(AP_WAYPOINT);
    //navigation_apsetmode(AP_HEADING | AP_ALTITUDE | AP_AIRSPEED);
    
    /* initialize aircraft pid constants */
    aircraft_init(&aircraft_values);
    
    /* init pid for elevator channel */
    pid_controller_init(&altitude_pid_controller,
        aircraft_values.pid_gain_elevator, aircraft_values.pid_derivative_time_elevator, aircraft_values.pid_integrator_time_elevator);
    pid_controller_set_coeffs(&altitude_pid_controller, 1.0, 1.0, 1.0);
    pid_controller_set_dt(&altitude_pid_controller, 0.1);

    /* init pid for aileron channel */
    pid_controller_init(&heading_pid_controller,
        aircraft_values.pid_gain_aileron, aircraft_values.pid_derivative_time_aileron, aircraft_values.pid_integrator_time_aileron);
    pid_controller_set_coeffs(&heading_pid_controller, 1.0, 1.0, 1.0);
    pid_controller_set_dt(&heading_pid_controller, 0.1);
    
        /* init pid for rudder channel */
    pid_controller_init(&heading_r_pid_controller,
        aircraft_values.pid_gain_rudder, aircraft_values.pid_derivative_time_rudder, aircraft_values.pid_integrator_time_rudder);
    pid_controller_set_coeffs(&heading_r_pid_controller, 1.0, 1.0, 1.0);
    pid_controller_set_dt(&heading_r_pid_controller, 0.1);
    
    /* init pid for elevator channel */
    pid_controller_init(&airspeed_pid_controller,
        aircraft_values.pid_gain_throttle, aircraft_values.pid_derivative_time_throttle, aircraft_values.pid_integrator_time_throttle);
    pid_controller_set_coeffs(&airspeed_pid_controller, 1.0, 1.0, 1.0);
    pid_controller_set_dt(&airspeed_pid_controller, 0.1);

    
	while (1) {
		nanosleep(&navigation_ts, NULL);
		
		/* copy global to local */
		pthread_mutex_lock(&global_pahrs_mutex);
		memcpy(&pahrs_copy_navigation, &global_pahrs, sizeof(pahrs_t));
		pthread_mutex_unlock(&global_pahrs_mutex);
		
		/* run iteration */
        navigation_task();
    }
	
	pthread_exit(NULL);
}

/**************** iteration for each timer overflow ******************/
void navigation_task( void ){
	if( navigation_apgetmode(AP_WAYPOINT) ) {
        if (mission) {
            if (mission->current)
                navigation_mission_task();
        }
    }
    else {
		if( navigation_apgetmode(AP_HEADING) )
			navigation_heading_task( ap_channels.heading );

		if( navigation_apgetmode(AP_ALTITUDE) )
			navigation_altitude_task( ap_channels.altitude );
            
		if( navigation_apgetmode(AP_AIRSPEED) )
			navigation_airspeed_task( ap_channels.airspeed );
	}
}

/**************** recursive waypoint advancer *********************/
void advance_current_waypoint( void ){
    /* indexes: -1 common */
    mission->current = mission->current->next;
    printf("Waypoint: %f %f %f %f\n",
        mission->current->latitude, mission->current->longitude, mission->current->altitude, mission->current->airspeed);
    printf("My index is: %d and the waypoint has index: %d\n", URUBU_ADDRESS, (int)mission->current->uavindex);
    if ((int)mission->current->uavindex != URUBU_ADDRESS && (int)mission->current->uavindex != -1)
        advance_current_waypoint();
}

/***************** MISSION HANDLER ********************************/
void navigation_mission_task( void ){
	/* estimate distance and course. course will fail on poles */
	float distance = estimate_distance();
	float desired_psi = estimate_course();
	
	/* within waypoint advance threshold? */
	if(distance <= 15.0){
        /* last one? cycle */
		if (mission->current->next == NULL)
            mission->current = mission->next;
        else 
            advance_current_waypoint();
	}
    
	/* call heading handler */
	navigation_heading_task(desired_psi);
	
	/* call altitude handler */
	navigation_altitude_task(mission->current->altitude);
	
	/* call airspeed handler */
	navigation_airspeed_task(mission->current->airspeed);
}

/********************* PROCESS HEADING PID ****************/
void navigation_heading_task( float desired_psi ){
	float psi_error = scale_degrees(desired_psi - pahrs_copy_navigation.angles[YAW]);
	if(fabs(psi_error) > 32.0*d2r)
		psi_error = sign(psi_error)*32.0*d2r;
    
    pid_controller_set_error(&heading_r_pid_controller, psi_error);
    
    /* psi error is heading. convert to roll */
    float phi_error = psi_error - pahrs_copy_navigation.angles[ROLL];
    if(fabs(phi_error) > 32.0*d2r)
        phi_error = sign(phi_error)*32.0*d2r;
			
	pid_controller_set_error(&heading_pid_controller, phi_error);
    
    global_ap_deflections.aileron += pid_controller_get_output_delta(&heading_pid_controller);
    global_ap_deflections.rudder += pid_controller_get_output_delta(&heading_pid_controller);
    
	/* check limits */
	if (fabs(global_ap_deflections.aileron) > 1.0)
		global_ap_deflections.aileron = sign(global_ap_deflections.aileron);
	
    if (fabs(global_ap_deflections.rudder) > 1.0)
		global_ap_deflections.rudder = sign(global_ap_deflections.rudder);
}

/****************** PROCESS ALTITUDE PID *******************/
void navigation_altitude_task( float desired_altitude ){
	float alt_error = desired_altitude - pahrs_copy_navigation.g_altitude;
    if (fabs(alt_error) > 5.0)
        alt_error = sign(alt_error) * 5.0;
    
    float vspeed_error = alt_error - pahrs_copy_navigation.velocities[2];
    if (fabs(vspeed_error) > 5.0)
        vspeed_error = sign(vspeed_error) * 5.0;
        
    pid_controller_set_error(&altitude_pid_controller, vspeed_error);
    
    // compensate for tilt
    global_ap_deflections.elevator += pid_controller_get_output_delta(&altitude_pid_controller);
	
	/* check limits */
	if (fabs(global_ap_deflections.elevator) > 1.0)
		global_ap_deflections.elevator = sign(global_ap_deflections.elevator);
}

/**** PROCESS AIRSPEED PID *****************************/
void navigation_airspeed_task(float desired_airspeed){
	float as_error = desired_airspeed - pahrs_copy_navigation.airspeed;
    if (fabs(as_error) > 10.0)
        as_error = sign(as_error) * 10.0;
    
    pid_controller_set_error(&airspeed_pid_controller, as_error);
    global_ap_deflections.throttle += pid_controller_get_output_delta(&airspeed_pid_controller);
    
	/* check limits */
	if (fabs(global_ap_deflections.throttle) > 1.0)
		global_ap_deflections.throttle = sign(global_ap_deflections.throttle);
}

/**** rad scaling utily function (from php prototype) ***/
float scale_degrees(float degrees){
	/* make sure we get right positive errors and left negative errors
	   aileron/rudder inherits correct sign (+ right, - left) */
	return (fabs(degrees) > pi) ? degrees-sign(degrees)*pi2 : degrees;
}

/**** SET **********************************************/
void navigation_apsetmode(unsigned char flag){
    autopilot_mode |= flag;
}

/**** UNSET **********************************************/
void navigation_apunsetmode(unsigned char flag){
    autopilot_mode = ~flag;
}

/**** GET **********************************************/
unsigned char navigation_apgetmode(unsigned char flag){
	return (autopilot_mode & flag) != 0;
}

/**** ESTIMATE DISTANCE FROM A(lat,lon) to B(lat,lon) **/
float estimate_distance( void ){
	/* calculate distance between current position and current target waypoint */
	double t1 = sin(pahrs_copy_navigation.latitude)*sin(mission->current->latitude);
	double t2 = cos(pahrs_copy_navigation.latitude)*cos(mission->current->latitude);
	double t3 = cos(pahrs_copy_navigation.longitude-mission->current->longitude);
	double t4 = t2*t3;
	double t5 = t1+t4;
	double distance = acos( t5 );
	
	/* convert to meters */
	float distance_m = distance * 6366689.6;
        
	return distance_m;
}

/**** ESTIMATE COURSE FROM A(lat,lon) to B(lat,lon) ****/
float estimate_course( void ){
	float course = fmod(atan2(sin(pahrs_copy_navigation.longitude-mission->current->longitude)*cos(mission->current->latitude),cos(pahrs_copy_navigation.latitude)*sin(mission->current->latitude)-sin(pahrs_copy_navigation.latitude)*cos(mission->current->latitude)*cos(pahrs_copy_navigation.longitude-mission->current->longitude)), pi2);
	
	/* quick hack for symetric sign error. needs elegancy tweak later */
	if(sin(mission->current->longitude - pahrs_copy_navigation.longitude) < 0.0)
		course = pi2 - course;
	if(course < 0.0)
		course = pi2-course;
	if(course > pi2)
		course = course-pi2;
		
	return(course);
}
