/*
 *  common.c
 *  
 *
 *  Created by Filipe Varela on 06/12/19.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

#include "common.h"

/***********************************************************************
	Microsecond precision difftime for "accurate" integration
************************************************************************/
float timeval_subtract(struct timeval *x, struct timeval *y){
	double a,b,result;
	
	a = x->tv_sec + (x->tv_usec/1000000.0);
	b = y->tv_sec + (y->tv_usec/1000000.0);
	
	result = a-b;
	
	return((float)result);
}

float ntohf(float source)
{
	#ifdef __LITTLE_ENDIAN__
	float destination;
	char *sourcePointer,*destinationPointer;
	int i;
	
	sourcePointer = (char *)&source;
	destinationPointer = (char *)&destination;
	
	for(i=3;i>=0;i--)
		destinationPointer[3-i] = sourcePointer[i];
		
	return destination;
	#else
	return source;
	#endif
}

float htonf(float source)
{
	#ifdef __LITTLE_ENDIAN__
	float destination;
	char *sourcePointer,*destinationPointer;
	int i;
	
	sourcePointer = (char *)&source;
	destinationPointer = (char *)&destination;
	
	for(i=3;i>=0;i--)
		destinationPointer[3-i] = sourcePointer[i];
		
	return destination;
	#else
	return source;
	#endif
}
