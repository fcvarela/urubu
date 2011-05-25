/*
 *  x-planeudp.h
 *  
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */
 
/* where we store all sensor data */
/* g_ gps, u_ ultrasound, c_ compass, p_ pressure */

#ifndef XPLANEUDP_H
#define XPLANEUDP_H

#define NUM_PACKETS 11

#include <sys/time.h>
#include "sensor_acquisition.h"

typedef struct{
	int		index;
	float	values[8];
} xplane_t;

typedef struct{
	unsigned char header[5];
	xplane_t packet;
} xplane_control_t;

int xplane_read_packet( void );
void xplane_start_listener( void );
float timeval_subtract(struct timeval *x, struct timeval *y);
void xplane_parse_packet(void);

#endif
