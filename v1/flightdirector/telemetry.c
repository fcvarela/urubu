/*
 *  telemetry_ctrl.c 
 *  
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/time.h>
#include <signal.h>
#include <pthread.h>
#include <arpa/inet.h>

#include "navigation.h"
#include "ahrs_qekf.h"
#include "common.h"
#include "telemetry.h"
#include "networkglue.h"
#include "actuator.h"

/* what will be exported */
extern pahrs_t global_pahrs;
extern pthread_mutex_t global_pahrs_mutex;
extern URUBU_ADDRESS;
pahrs_t pahrs_copy_telemetry;

/* initialize telemetry engine */
void telemetry_init(void){
    struct timespec telemetry_ts;

    printf("Thread TELEMETRY detached with id: %x\n", (unsigned int)pthread_self());

    telemetry_ts.tv_sec = 0;
    telemetry_ts.tv_nsec = 10 * 10000000; /* 10 Hz */

    while(1){
        nanosleep(&telemetry_ts,NULL);
        /* copy to local copy*/
        pthread_mutex_lock(&global_pahrs_mutex);
        memcpy(&pahrs_copy_telemetry, &global_pahrs, sizeof(pahrs_t));
        pthread_mutex_unlock(&global_pahrs_mutex);

        /* printf("Telemetry[%x]: Will run telemetry task\n", (unsigned int)pthread_self()); */
        telemetry_task();
    }

    pthread_exit(NULL);
}

/* triggered on telemetry timer overflow ~ 10Hz */
void telemetry_task(void){
    char		startstop[2] = {'A','Z'};
    int			res;

    float telemetry_packet[9] = {
        htonf(pahrs_copy_telemetry.angles[0]*r2d),
        htonf(pahrs_copy_telemetry.angles[1]*r2d),
        htonf(pahrs_copy_telemetry.angles[2]*r2d),
        htonf(pahrs_copy_telemetry.u_altitude),
        htonf(pahrs_copy_telemetry.latitude*r2d),
        htonf(pahrs_copy_telemetry.longitude*r2d),
        htonf(pahrs_copy_telemetry.g_altitude),
        htonl(pahrs_copy_telemetry.satellites),
        htonl(URUBU_ADDRESS),
    };

    /* do we have a simulated environment? then broadcast the udp packets directly to the groundstation listen port */
    res = network_write_telemetry(&startstop[0], sizeof(startstop[0]));
    res = network_write_telemetry(&telemetry_packet, sizeof(telemetry_packet));
    res = network_write_telemetry(&startstop[1], sizeof(startstop[1]));
    if(res < 0)
        perror("network_write_telemetry");

    /* perform actuator task once per telemetry actuation. this needs to be separated
       later due to the possibility of errors locking the actuator and telemetry */

    actuate();
}
