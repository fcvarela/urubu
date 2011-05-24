/*
 *  common.h
 *  
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

#ifndef COMMON_H
#define COMMON_H

#include <sys/time.h>
#include <stdio.h>

/* adc to voltage for scale factors */
#define a2v_10bit 00.0048828125
#define a2v_12bit 00.001220703125

/* radians to degrees and degrees to radians */
#define r2d 57.29577951308
#define d2r 0.01745329252

/* Gravity scalar value */
/*
#define G 9.797645*/
#define G 9.80665

/* extract sign of variable */
#define sign(arg) (arg>=0 ? 1:-1)

/* pi and float pi */
#define pi 3.141592
#define pi2 6.283184

/* accessor proxys */
#define ROLL 0
#define PITCH 1
#define YAW 2

/* frequency sampler */
float timeval_subtract(struct timeval *x, struct timeval *y);
float ntohf(float source);
float htonf(float source);

#endif
