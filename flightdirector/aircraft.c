/*
 *  aircraft.c
 *
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 *  Definitions for specific airframe. Needs to be dynamic. Needs post filter
 *  for plugin ability in control geometry. Possibly callback on setup to get user
 *  to supply us a pointer to a new struct.
 *
 */

#include "common.h"
#include "aircraft.h"

aircraft_values_t aircraft_values;

void aircraft_init(aircraft_values_t *aircraft_values) {
    #ifdef AIRCRAFT_MODEL_PT60
    aircraft_values->pid_gain_elevator = 0.015;
    aircraft_values->pid_derivative_time_elevator = 0.002;
    aircraft_values->pid_integrator_time_elevator = 100.0;

    aircraft_values->pid_gain_aileron = 0.3;
    aircraft_values->pid_derivative_time_aileron = 0.002;
    aircraft_values->pid_integrator_time_aileron = 80.0;

    aircraft_values->pid_gain_rudder = 0.3;
    aircraft_values->pid_derivative_time_rudder = 0.002;
    aircraft_values->pid_integrator_time_rudder = 80.0;

    aircraft_values->pid_gain_throttle = 0.05;
    aircraft_values->pid_derivative_time_throttle = 0.1;
    aircraft_values->pid_integrator_time_throttle = 10.0;

#endif
}
