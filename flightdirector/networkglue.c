/*
 *  networkglue.c
 *  
 *
 *  Created by Filipe Varela on 06/12/13.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>			/* socket */
#include <netinet/in.h>			/* socket */
#include <arpa/inet.h>

#include "networkglue.h"
#include "sensor_acquisition.h"
#include "mission.h"
#include "common.h"

struct sockaddr_in robostix_socket_addr;
struct sockaddr_in telemetry_socket_addr;
struct sockaddr_in control_socket_addr;
struct sockaddr_in xplane_socket_addr;
struct sockaddr_in xplanectrl_socket_addr;

int global_telemetry_socket; /* data to groundstation */
int global_control_socket; /* data from groundstation */
int global_xplane_socket; /* data from x-plane to simulate sensor */
int global_xplanectrl_socket; /* data to x-plane to simulate servos */

extern char * GROUNDSTATION_IP_ADDRESS;

/************************************* MAKE UDP SOCKET **************************************/
int network_make_sockets(void)
{	
	/********************* TELEMETRY SOCKET ******************/
    if ((global_telemetry_socket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("global_telemetry_socket create");
        return -1;
    }
        
    memset((char*) &telemetry_socket_addr, 0, sizeof(telemetry_socket_addr));
    telemetry_socket_addr.sin_family = AF_INET;
    printf("Creating GS socket: %s\n", GROUNDSTATION_IP_ADDRESS);
    telemetry_socket_addr.sin_addr.s_addr = inet_addr(GROUNDSTATION_IP_ADDRESS);
    telemetry_socket_addr.sin_port = htons(TELEMETRY_UDP_PORT);
//	int yes=1;
//	setsockopt(global_telemetry_socket, SOL_SOCKET, SO_BROADCAST, (char *)&yes, sizeof(yes));
	
	/********************* CONTROL SOCKET ******************/
    /* Bind all interfaces. All UAVs get all control packets from ground */
    if ((global_control_socket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("global_control_socket create");
        return -1;
    }
        
    memset((char*) &control_socket_addr, 0, sizeof(control_socket_addr));
    control_socket_addr.sin_family = AF_INET;
    control_socket_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    control_socket_addr.sin_port = htons(CONTROL_UDP_PORT);

	int bind_result2 = bind(global_control_socket, (struct sockaddr *)&control_socket_addr,(unsigned int)sizeof(control_socket_addr));
	if(bind_result2 < 0)
		perror("control_socket_bind");
	
	/************************ XPLANE SOCKET *****************************/
	if (SENSOR_BOARD == XPLANE_SENSOR) {
		if ((global_xplane_socket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
		{
			perror("global_xplane_socket create");
			return -1;
		}
			
		memset((char*) &xplane_socket_addr, 0, sizeof(xplane_socket_addr));
		xplane_socket_addr.sin_family = AF_INET;
		xplane_socket_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
		xplane_socket_addr.sin_port = htons(XPLANE_UDP_PORT);
		
		int bind_result = bind(global_xplane_socket, (struct sockaddr *)&xplane_socket_addr,(unsigned int)sizeof(xplane_socket_addr));
		if(bind_result < 0)
			perror("x_plane_socket_bind");
			
		/********************* XPLANECTRL SOCKET ******************/
		if ((global_xplanectrl_socket = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
		{
			perror("global_xplanectrl_socket create");
			return -1;
		}
			
		memset((char*) &xplanectrl_socket_addr, 0, sizeof(xplanectrl_socket_addr));
		xplanectrl_socket_addr.sin_family = AF_INET;
		xplanectrl_socket_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
		xplanectrl_socket_addr.sin_port = htons(XPLANECTRL_UDP_PORT);
		// setsockopt(global_xplanectrl_socket, SOL_SOCKET, SO_BROADCAST, (char *)&yes, sizeof(yes));
	}
	return 0;
}

/************* CLEAN SHUTDOWN ***********************/
void network_destroy_sockets( void ){
	close(global_telemetry_socket);
	close(global_xplane_socket);
	close(global_xplanectrl_socket);
}

/************************************ READ DATA FROM TELEMETRY/COMM SOCKET ****************/
int network_read_control(void *read_into, size_t len){
	unsigned int sin_length = sizeof(control_socket_addr);
	int bytes;
	
	bytes = recvfrom(global_control_socket, read_into, len, MSG_WAITALL, (struct sockaddr *)&control_socket_addr, &sin_length);
	if(bytes < 0)
		perror("control socket read error");
    printf("Got a control packet\n");
	return bytes;
}

/******************************** READ MISSION WAYPOINTS FROM COMM SOCKET ****************/
int network_read_mission(void) {
    extern mission_t *mission;
    unsigned int num_waypoints = 0, i, sin_length = sizeof(control_socket_addr);
    int bytes;
    float wp[5];
    waypoint_t new_wp;
    
    /* first byte is number of waypoints */
    bytes = recvfrom(global_control_socket, &num_waypoints, sizeof(unsigned int), MSG_WAITALL, (struct sockaddr *)&control_socket_addr, &sin_length);
    
    /* make sure we cleanup everything */
    mission_cleanup(mission);
    
    /* re-init */
    mission = mission_init();
    
    for (i=0; i<num_waypoints; i++) {
        bytes = recvfrom(global_control_socket, &wp, sizeof(wp), MSG_WAITALL, (struct sockaddr *)&control_socket_addr, &sin_length);
        if (bytes < 0) {
            perror("network_read_mission");
            break;
        }
        /* append this waypoint */
        new_wp.latitude = wp[0] * d2r;
        new_wp.longitude = wp[1] * d2r;
        new_wp.altitude = wp[2];
        new_wp.airspeed = wp[3];
        new_wp.uavindex = wp[4];
        printf("Received mission waypoint with index: %f\n", wp[4]);
        
        mission_add_waypoint(mission, new_wp);
    }
    mission->current = mission->next;
    
    return bytes;
}

/************************************ WRITE DATA TO TELEMETRY/COMM SOCKET ****************/
int network_write_telemetry(void *read_from, size_t len){
	unsigned int sin_length = sizeof(telemetry_socket_addr);
	int bytes;
	
	bytes = sendto(global_telemetry_socket, read_from, len, MSG_WAITALL, (struct sockaddr *)&telemetry_socket_addr, sin_length);
	if(bytes < 0)
		perror("telemetry socket write error");	
	return bytes;
}

/************************************* READ DATA FROM XPLANE **********************************/
int network_read_xplane(void *read_into, size_t len){
	unsigned int sin_length = sizeof(xplane_socket_addr);
	int	bytes;
	bytes = recvfrom(global_xplane_socket, read_into, len, 0, (struct sockaddr *)&xplane_socket_addr, &sin_length);
	if(bytes < 0)
		perror("xplane socket read error");
	return bytes;
}

/************************************* WRITE DATA TO XPLANE **********************************/
int network_write_xplane(void *read_into, size_t len){
	unsigned int sin_length = sizeof(xplane_socket_addr);
	int	bytes;
	bytes = sendto(global_xplanectrl_socket, read_into, len, MSG_WAITALL, (struct sockaddr *)&xplanectrl_socket_addr, sin_length);
	if(bytes < 0)
		perror("xplanectrl socket write error");
	return bytes;
}
