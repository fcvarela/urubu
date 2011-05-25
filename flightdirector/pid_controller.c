/*
 *  pid_controller.c
 *
 *
 *  Created by Filipe Varela on 08/03/17.
 *  Copyright 2008 Filipe Varela. All rights reserved.
 *
 */

#include <stdio.h>
#include <string.h>
#include "pid_controller.h"

#define PID_CONTROLLER_DEBUG

void pid_controller_init(pid_controller *self, float kP, float td, float ti)
{
    memset(self, 0, sizeof(self));

    self->kP = kP;
    self->td = td;
    self->ti = ti;
}

void pid_controller_set_coeffs(pid_controller *self, float alpha, float beta, float gamma)
{
    self->alpha = alpha;
    self->beta = beta;
    self->gamma = gamma;
}

void pid_controller_set_dt(pid_controller *self, float dt)
{
    self->dt = dt;
}

void pid_controller_set_error(pid_controller *self, float err)
{
    /* proportional */
    self->error = err;
    self->eP = self->beta * err;
    self->p_component = self->eP - self->ePp;

    /* back propagate */
    self->ePp = self->eP;

    /* integrator */
    self->i_component = self->error * (self->dt/self->ti);

    /* derivative */
    self->tf = self->alpha*self->td;
    self->eD = self->error*self->gamma;
    self->eDf = self->eDf/(self->dt/self->tf+1)+self->eD*(self->dt/self->tf)/(self->dt/self->tf+1);
    self->d_component = self->td/self->dt*(self->eDf-2*self->eDfp+self->eDfpp);

    /* back-propagate */
    self->eDfpp = self->eDfp;
    self->eDfp = self->eDf;

    self->output = self->kP * (self->p_component + self->i_component + self->d_component);
}
