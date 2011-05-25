/*
 *  ahrs.h
 *  
 *
 *  Created by Filipe Varela on 06/12/13.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

/* position and attitude reference system type definition. all units IS/SI */
/* length: m, velocities: m.s^-1 accelerations: m.s^-2 rates: rad.s^-1 */

#define NORTH 0
#define EAST 1
#define DOWN 2

/*#define USE_QUATS*/

typedef struct{
	float			angles[3];
	float			rates[3];
	float			quat[4];
	float			velocities[3];
	float			accelerations[3];
	float			airspeed,airaccel;
	float			latitude,longitude,time,g_altitude,u_altitude,p_altitude,satellites;
} pahrs_t;

/* prototypes */
void pahrs_init( void );
void pahrs_process_filter( void );

void pahrs_integrate_gyro_quat( void );
void pahrs_quat_to_euler( void );
void pahrs_gyro_to_angle( void );
void pahrs_accel_to_angle( void );

void pahrs_accel_to_position(void);
