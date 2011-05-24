/*
 *  navigation.h
 *  
 *
 *  Created by Filipe Varela on 06/12/18.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 *	Theory: Parse XML mission file.
				Read aircraft type
					Read aircraft xml file
						Parse max deflections,speed,TO speed
							Parse surface types (AIL+RUD+ELEV+MOTOR / ELEVONS)
					Parse pid coefficients for aircraft type
			Import waypoints and apmode for flight
			Process navigation (error, distance, required deflections)
			Actuate if apmode so requires
 */

/************* autopilot modes
bit 0 - heading hold (horizontal nav. leave off for waypoint following)
bit 1 - altitude hold (vertical nav)
bit 2 - airspeed hold (speed ctrl)
bit 3 - waypoint follow (navigate thru series of waypoints, each with lla+spd+script)
bit 4 - full manual from rc tx
bit 5 - reserved
bit 6 - reserved
bit 7 - reserved

Explanatin: bits 0 to 2 are used for autopilot command.
Leave all off but 3 to follow a predefined mission.
If 3 is active, it'll determine that the autopilot is in full control.
Mission script MUST include, for each waypoint:
	Latitude
	Longitude
	Altitude of target (vspeed is calculated)
	Airspeed of target (how fast you should get there)
	Script: (move to next, circle for n minutes, etc. define this later)
*/

#define AP_HEADING ((unsigned char) (1 << 0))
#define AP_ALTITUDE ((unsigned char) (1 << 1))
#define AP_AIRSPEED ((unsigned char) (1 << 2))
#define AP_WAYPOINT ((unsigned char) (1 << 3))
#define AP_RCMANUAL ((unsigned char) (1 << 4))

typedef struct{
	float heading;
	float altitude;
	float airspeed;
} ap_packet_t;

void navigation_init( void );
void navigation_task( void );
void navigation_mission_task( void ); /* determined necessary heading */
void navigation_heading_task( float target_heading );
void navigation_altitude_task( float target_altitude );
void navigation_airspeed_task( float target_airspeed );
unsigned char navigation_apgetmode( unsigned char flag );
void navigation_apsetmode( unsigned char flag );
void navigation_apunsetmode( unsigned char flag );
float estimate_distance(void);
float estimate_course(void);
float scale_degrees( float degrees);
