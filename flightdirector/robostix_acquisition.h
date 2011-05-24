/*
 *  robostix_acquisition.h
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

/********************************* PROTOTYPES ******************/
void robostix_start_listener(void);
void robostix_filter_packet(void);
int robostix_read_packet(void);
void robostix_parse_accels(void);
void robostix_parse_gyros(void);
void robostix_compensate_gyro_25v_ref(void);
void robostix_compensate_gyro_temp_drifts(void);
