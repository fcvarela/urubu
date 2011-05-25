/*
 *  aircraft.h
 *
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 *  Definitions for specific airframe. Needs to be dynamic. Needs post filter
 *  for plugin ability in control geometry.
 *
 */

#ifndef AIRCRAFT_H
#define AIRCRAFT_H

/* suppose your servos do 90 degrees (-45 to 45) and you want them to only to
   40 (-20 to 20) to respect the surface model you simulated in x-plane,
   set the scale factor to 90 / 40;

ie: pt60 model in x-plane is -20 to 20 all surfaces, but my servos do -45 to 45...
*/

typedef struct{
    float pid_gain_elevator;
    float pid_gain_aileron;
    float pid_gain_rudder;
    float pid_gain_throttle;
    float pid_derivative_time_elevator;
    float pid_derivative_time_aileron;
    float pid_derivative_time_rudder;
    float pid_derivative_time_throttle;
    float pid_integrator_time_elevator;
    float pid_integrator_time_aileron;
    float pid_integrator_time_rudder;
    float pid_integrator_time_throttle;
    float aileron_scale_factor;
    float elevator_scale_factor;
    float rudder_scale_factor;
} aircraft_values_t;

/* moving surface global_deflections */
typedef struct{
    float aileron;
    float elevator;
    float rudder;
    float throttle;
} deflection_t;

#define RC_CHANNEL_AILERON 0
#define RC_CHANNEL_ELEVATOR 1
#define RC_CHANNEL_RUDDER 2
#define RC_CHANNEL_THROTTLE 3

#define AIRCRAFT_MODEL_PT60

void aircraft_init(aircraft_values_t *ac_values);

#endif
