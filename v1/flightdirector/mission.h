/*
 *  mission.h
 *  
 *
 *  Created by Filipe Varela on 08/03/24.
 *  Copyright 2008 Filipe Varela. All rights reserved.
 *
 */

#ifndef MISSION_H
#define MISSION_H

typedef struct waypoint {
	struct waypoint *next;
	float latitude;
	float longitude;
	float altitude;
	float airspeed;
    float uavindex;
} waypoint_t;

typedef struct {
	struct waypoint *next, *last, *current;
} mission_t;

mission_t * mission_init(void);
void mission_add_waypoint(mission_t *m, waypoint_t wp);
void mission_cleanup(mission_t *m);

#endif