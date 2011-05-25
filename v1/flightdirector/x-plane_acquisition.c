/*
 *  x-planeudp.c
 *  
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <arpa/inet.h>
#include <math.h>

#include "x-plane_acquisition.h"
#include "networkglue.h" 
#include "ahrs_qekf.h"
#include "common.h"
#include "navigation.h"
#include "aircraft.h"

/* global ahrs struct and mutex */
extern pahrs_t local_pahrs, global_pahrs;
extern pthread_mutex_t global_pahrs_mutex;

xplane_t packet;

/* quick hack for x-plane control programming */
extern deflection_t global_ap_deflections;
extern deflection_t global_manual_deflections;

/********************************* MAIN LOOP ********************************************************/
void xplane_start_listener( void ){
	/* acquisition loop  */
	while(1){
		if(xplane_read_packet()){
			/* copy to global for other threads */
			pthread_mutex_lock(&global_pahrs_mutex);
			memcpy(&global_pahrs, &local_pahrs, sizeof(pahrs_t));
			pthread_mutex_unlock(&global_pahrs_mutex);
		}
	}
}

/****************************** PARSE NETWORK CHUNK INTO PACKET UNITS ********************/
int xplane_read_packet( void ){
	char			data[5+(NUM_PACKETS*36)];
	int				i,j,*index,_index;
	float			*block;
	
	int bytes = network_read_xplane(&data,sizeof(data));
	if(bytes < 0)
		perror("network_read_xplane");
    
    /* IMPORTANT: AS OF V8, ALL UDP PACKETS ARE BIG-ENDIAN AS THEY SHOULD */
	for(i=0;i<NUM_PACKETS;i++){
        /* GET PACKET INDEX */
		index = (int *)&data[5+i*36];
		_index = *index;
		_index = ntohl(_index);
		packet.index = _index;
        
        block = (float *)&data[5+i*36+4];
        for (j=0;j<8;j++)
            packet.values[j] = ntohf(block[j]);
		xplane_parse_packet();
	}
	return 1;
}

/******************** PARSE PACKET VALUES INTO INTERNAL SENSOR VARIABLES **************/
void xplane_parse_packet(void)
{
    static float real_lat, real_lon, real_alt;/*test purposes*/
	struct timeval start,end;

	switch (packet.index)
    {
		case 2:
			local_pahrs.airaccel = (packet.values[1]-local_pahrs.airspeed)/0.1;
			local_pahrs.airspeed = packet.values[1];
		break;
		/* rates: xplane outputs in deg/sec. we want rads/sec */
        /* this replaces real sensor i_rates */
		case 15:
			local_pahrs.rates[1] = packet.values[0]*d2r;
			local_pahrs.rates[0] = packet.values[1]*d2r;
			local_pahrs.rates[2] = packet.values[2]*d2r;
		break;
		
		/* magnetic heading 16.3 in degrees. need to convert to rads */
        /* this replaces real sensor angles from i_rates */
		case 16:
			local_pahrs.angles[0] = packet.values[1]*d2r;
			local_pahrs.angles[1] = packet.values[0]*d2r;
			local_pahrs.angles[2] = packet.values[2]*d2r;
		break;
		
		/* GPS */
		case 18:
            real_lat = packet.values[0];
            real_lon = packet.values[1];
            /* simulate real gps update rate (1-4 Hz) */
            gettimeofday(&end,0);
            if (timeval_subtract(&end,&start) < 1.0/4.0 ) {
                return;
            }
                
            /* got here? time to update */
            gettimeofday(&start,0);
			local_pahrs.latitude = packet.values[0]*d2r;
			local_pahrs.longitude = packet.values[1]*d2r;
			local_pahrs.g_altitude = real_alt = packet.values[2];
		break;
        
        /* velocities */
        case 19:
            /* this replaces real sensor unbiased accelerations * dt from kalman filter */
            
            /* latitude: integrate incoming speed to distance (0.1 dt) then convert */
            /*float _1deglat_meters = 111120.0;*/
            local_pahrs.latitude -= packet.values[5] * 0.1 / 111050.0 * d2r;
            //printf("GPSLat: %f EstimatedLat: %f Delta(Err): %f\n", real_lat, local_pahrs.latitude * r2d, fabs(real_lat - local_pahrs.latitude*r2d));
            
            /* longitude: interate incoming speed to distance (0.1 dt) then convert */
            /*float _1deglon_meters = cos(local_pahrs.latitude) * 111325.0;  1 degree of longitude at this latitude in meters */
            local_pahrs.longitude += (packet.values[3] * 0.1) / (cos(local_pahrs.latitude) * 111325.0) * d2r;
            //printf("GPSLon: %f EstimatedLon: %f Delta(Err): %f\n", real_lon, local_pahrs.longitude * r2d, fabs(real_lon - local_pahrs.longitude*r2d));
            
            /* how to check longitude ? */
            local_pahrs.velocities[0] = packet.values[3]; /* east to x m/s */
            local_pahrs.velocities[1] = packet.values[5]; /* south to z m/s */
            local_pahrs.velocities[2] = packet.values[4] * 3.2808399; /* m/s to fps */
        break;
	}
}
