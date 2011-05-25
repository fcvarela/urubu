/*
 *  robostix_acquisition.c
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

/* IMPORTANT: CODE HERE IS PREP'D FOR ADXRS150. TEMP CALIBRATION AND ADC SCALE VALUES DEPENDS ON IMU (v1,v2) GYRO */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>

#include "sensor_acquisition.h"
#include "robostix_acquisition.h"
#include "networkglue.h"
#include "ahrs_qekf.h"
#include "common.h"
#include "serialglue.h"

/* global sensor struct */
extern sensor_t global_sensor;

/* external global pahrs struct */
extern pahrs_t local_pahrs;

/* state variables */
double gyro_25v_correction[3]; /* correction factor for null offset */
/* raw adc temperature and null temperature */
double raw_gyro_temperatures[3]; /* roll,pitch,yaw */
double raw_gyro_temperatures_null[3] = {526.0,526.0,526.0}; /* null values at 25deg (nominal) */
/* raw adc rate and null rate */
double raw_gyro_rates[3]; /* roll,pitch,yaw */
double raw_gyro_rates_null[3] = {480.0,512.0,480.0}; /* rateout at idle (not spinning) */
/* raw adc gyro 2.5volt reference outputs (for tension (voltage) variation estimate) */
double raw_gyro_25v[3]; /* roll, pitch, yaw */
/* raw adc accelerometers */
double raw_accels[3][2]; /* pitch board x,y roll board x,y yaw board x,y */
double raw_accels_null[3][2] = {
	{510.0,510.0},
	{510.0,510.0},
	{504.0,504.0}};
    
int imu_fd, robostix_fd;

/********************************* MAIN LOOP ********************************************************/
void robostix_start_listener( void ) {
	struct timespec sensor_acquisition_ts;
	sensor_acquisition_ts.tv_sec = 0;
	sensor_acquisition_ts.tv_nsec = 1000000000 / 100; /* 100 Hz. estimated imu freq is 45 Hz */
	struct timeval start,end;
	
	pahrs_init();
    
    // open serial ports
    open_serial_port("/dev/cu.robostix", 115200);
    open_serial_port("/dev/cu.imu", 115200);
	
	/* acquisition loop */
	while(1) {
		gettimeofday(&start,0);
		
		/* small delay of a few microseconds to keep this from hogging us  on failure */
		usleep(10000); /* 100Hz, way faster than imu reports */
        
		if (robostix_read_packet()) {
			gettimeofday(&end,0);
			global_sensor.dt = timeval_subtract(&end,&start);
			robostix_filter_packet();
			pahrs_process_filter();
		}
	}	
}

/************************************** SERIALIZES FILTERING OF CAPTURED DATA ******************************/
void robostix_filter_packet(void) {
	robostix_parse_accels();
	robostix_compensate_gyro_25v_ref();
	robostix_compensate_gyro_temp_drifts();
}

/************************************* PARSE ACCELS *******************************************************/
void robostix_parse_accels(void) {
	/* pitch board */
	raw_accels[0][0] = raw_accels[0][0] - raw_accels_null[0][0];
	raw_accels[0][1] = raw_accels[0][1] - raw_accels_null[0][1];
	
	/* roll board */
	raw_accels[1][0] = raw_accels[1][0] - raw_accels_null[1][0];
	raw_accels[1][1] = raw_accels[1][1] - raw_accels_null[1][1];
	
	/* yaw board */
	raw_accels[2][0] = raw_accels[2][0] - raw_accels_null[2][0];
	raw_accels[2][1] = raw_accels[2][1] - raw_accels_null[2][1];
		   
	/* X acceleration: roll board->y value + yaw board->x value */
	global_sensor.i_accels[0] = (raw_accels[0][0] + raw_accels[2][1])/2;
	
	/* Y acceleration: pitch board->-y value + yaw board->y value */
	global_sensor.i_accels[1] = (-raw_accels[1][0] + raw_accels[2][0])/2;
	
	/* Z acceleration: pitch board->x value + roll board->x value */
	global_sensor.i_accels[2] = (raw_accels[0][1] + raw_accels[1][1])/2;
}

/**************************************** PARSE GYROS DIRECTLY TO RATES ***********************************/
void robostix_parse_gyros(void) {
	int i;
	
	for(i=0;i<3;i++) {
		global_sensor.i_rates[i] = (raw_gyro_rates[i] - raw_gyro_rates_null[i])*a2v_10bit/0.0125;
	}
}

/************************************** GYRO 2.5v REF CORRECTION ******************************************/
void robostix_compensate_gyro_25v_ref(void) {
	int i;
	/*printf("Raw rates: %f %f %f\n", raw_gyro_rates[0], raw_gyro_rates[1], raw_gyro_rates[2]);*/
	for(i=0;i<3;i++) {
		gyro_25v_correction[i] = (2.5 / raw_gyro_25v[i]) * 1024;
		gyro_25v_correction[i] = (gyro_25v_correction[i] / 5.0);
		raw_gyro_rates[i] = gyro_25v_correction[i] * raw_gyro_rates[i];
		raw_gyro_temperatures[i] = gyro_25v_correction[i] * raw_gyro_temperatures[i];
	}
}

/***************************************************************************
	3 POINT GYRO TEMPERATURE CALIBRATION BASED ON ANALOG'S APPNOTE.
	NEEDS ADDITIONAL WORK AND WE REALLY SHOULD IGNORE TABLE VALUES AND
	MEASURE EACH OF OUR GYROS AND THEN CREATE A TEMPvsOUTPUT TABLE FOR THEM
***************************************************************************/
void robostix_compensate_gyro_temp_drifts() {
	/* local variables */
	double gyro_null[3],gyro_scale_factor[3];
	double gyro_temp_differential[3];
	double gyro_temp_differential_squared[3];
	double gyro_rates_temp_compensated[3];
	int i;
	
	/* if we convert to rads BEFORE the correction, can the extra precision of
	   the double's mantissa increase the scale precision? probably not, but we'll
	   try it later just to be sure. */
	
	for(i=0;i<3;i++) {
		/* calculate null temp point (temp out at current vout) */
		/* current temp - reference temp (25 degrees celsius) */
		gyro_temp_differential[i] = (raw_gyro_temperatures[i]-raw_gyro_temperatures_null[i])*a2v_10bit;
		/* previous var square */
		gyro_temp_differential_squared[i] = gyro_temp_differential[i]*gyro_temp_differential[i];
		/* current null value (center) from reference null value */
		gyro_null[i] = (raw_gyro_rates_null[i]*a2v_10bit) + 0.0086*(gyro_temp_differential[i])+0.03597*(gyro_temp_differential_squared[i]);
		/* compensate current output with temp correction */
		gyro_rates_temp_compensated[i] = (raw_gyro_rates[i]*a2v_10bit) - gyro_null[i];
		/* convert to degrees by applying the scale factor according to temp */
		gyro_scale_factor[i] = 12.744 + 1.26056*(gyro_temp_differential[i])+0.6728*(gyro_temp_differential_squared[i]);
		/* transform P into corrected degrees per second */
		global_sensor.i_rates[i] = gyro_rates_temp_compensated[i] / (gyro_scale_factor[i]/1000);
		/*  WE'RE FINISHED EXECUTING OUR CORRECTIONS.
		    WE NOW HAVE EXPORTED CORRECTED VALUES FOR P,Q,R (ROLL,PITCH,YAW) as double corrected_rates in DEGS.
		    WE WANT RADS */
		global_sensor.i_rates[i] = global_sensor.i_rates[i]*d2r;
	}
}

/************************************** READS DATA INTO	SENSOR PACKET **********************/
int robostix_read_packet( void ) {
        // 0 = nothing ok
        // 1 = imu ok
        // 2 = sensors ok
        // 3 = imu + sensors ok
        
	char c;
	unsigned char compass_high,compass_low;
	short temp;
    int imu = 0, sensors = 0;
	
    // FIRST READ IMU
    read(imu_fd, &c, 1);
    if (c == 'A') {
        // pitch board
        read(imu_fd, &temp,2); raw_gyro_rates[1] = ntohs(temp);        /* gyro rateout */
        read(imu_fd, &temp,2); raw_gyro_25v[1] = ntohs(temp);          /* 2.5v ref */
        read(imu_fd, &temp,2); raw_gyro_temperatures[1]=ntohs(temp);   /* gyro temp */
        read(imu_fd, &temp,2); raw_accels[1][0] = ntohs(temp);         /* accel y raw (real axis = -y) */
        read(imu_fd, &temp,2); raw_accels[1][1] = ntohs(temp);         /* accel x raw (real axis = z ) */
        
        // roll board
        read(imu_fd, &temp,2); raw_gyro_rates[0] = ntohs(temp);		/* gyro rateout */
        read(imu_fd, &temp,2); raw_gyro_25v[0] = ntohs(temp);			/* 2.5v ref */
        read(imu_fd, &temp,2); raw_gyro_temperatures[0]=ntohs(temp);	/* gyro temp */
        read(imu_fd, &temp,2); raw_accels[0][0] = ntohs(temp);			/* accel y raw (real axis = x) */
        read(imu_fd, &temp,2); raw_accels[0][1] = ntohs(temp);			/* accel x raw (real axis = z) */
        
        // yaw board
        read(imu_fd, &temp,2); raw_gyro_rates[2] = ntohs(temp);		/* gyro rateout */
        read(imu_fd, &temp,2); raw_gyro_25v[2] = ntohs(temp);			/* 2.5v ref */
        read(imu_fd, &temp,2); raw_gyro_temperatures[2]=ntohs(temp);	/* gyro temp */
        read(imu_fd, &temp,2); raw_accels[2][0] = ntohs(temp);			/* accel y raw (real axis = y) */
        read(imu_fd, &temp,2); raw_accels[2][1] = ntohs(temp);			/* accel x raw (real axis = x) */
        
        read(imu_fd, &temp,2); global_sensor.i_battery = ntohs(temp);	/* battery voltage */
        
        // find end byte
        read(imu_fd, &c, 1);
        if (c == 'Z')
            imu = 1; // packet ok
    }
    
	// now read data from robostix
    read(robostix_fd, &c, 1);
    if (c == 'B') {
        // GPS
        read(robostix_fd, &global_sensor.g_altitude,4); global_sensor.g_altitude = ntohf(global_sensor.g_altitude);
        read(robostix_fd, &global_sensor.g_longitude,4); global_sensor.g_longitude = ntohf(global_sensor.g_longitude)*d2r;
        read(robostix_fd, &global_sensor.g_latitude,4); global_sensor.g_latitude = ntohf(global_sensor.g_latitude)*d2r;
        read(robostix_fd, &global_sensor.g_satelites,4); global_sensor.g_satelites = ntohl(global_sensor.g_satelites);
        read(robostix_fd, &global_sensor.g_time,4); global_sensor.g_time = ntohf(global_sensor.g_time);
        
        // ultrasonic altimeter
        read(robostix_fd, &c, 1);
        global_sensor.u_altitude = (((c * 5.0) / 255.0) / 0.01) * 2.24;
        
        // static pressure transducer
        read(robostix_fd, &temp, 2); global_sensor.p_static = ntohs(temp);
        read(robostix_fd, &temp, 2); global_sensor.p_dynamic = ntohs(temp);
        
        // read compass
        read(robostix_fd, &compass_low,1);
        read(robostix_fd, &compass_high,1);
        global_sensor.c_heading = ((compass_high * 256.0) + compass_low)/10.0*d2r;
        
        // read trail
        read(robostix_fd, &c, 1);
        if (c == 'Y')
            sensors = 2;
        }
	
	return imu + sensors;
}
