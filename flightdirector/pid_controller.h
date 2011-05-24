/*
 *  pid_controller.h
 *  
 *
 *  Created by Filipe Varela on 08/03/17.
 *  Copyright 2008 Filipe Varela. All rights reserved.
 *
 */

#ifndef _PID_CONTROLLER_H
#define _PID_CONTROLLER_H

typedef struct _pid_controller pid_controller;

struct _pid_controller
{
    float alpha, beta, gamma; /* weight factors */
    float kP; /* proportional (and global) gain */
    float td,ti,dt,tf; /* time weights */
    float error, eP, ePp;
    float eD, eDf, eDfp, eDfpp; /* error deriv prev, prev prev */
    
    float p_component, i_component, d_component;
    float output;
};

void pid_controller_init(pid_controller *self, float kP, float td, float ti);
void pid_controller_set_coeffs(pid_controller *self, float alpha, float beta, float gamma);
void pid_controller_set_dt(pid_controller *self, float dt);
void pid_controller_set_error(pid_controller *self, float err);

__inline__ static float pid_controller_get_output_delta(pid_controller *self) {
    return self->output;
}

#endif
