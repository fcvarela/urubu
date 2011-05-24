##----------------------------------------------------------------------------
# Created with genmake.pl v1.1 on Wed Mar 14 10:03:12 2007
# genmake.pl home: http://muquit.com/muquit/software/
# Copryright: GNU GPL (http://www.gnu.org/copyleft/gpl.html)
##----------------------------------------------------------------------------
rm=/bin/rm -f
CC=gcc
DEFS=-DSTRICT -Wall -O3
PROGNAME=flightdirector
INCLUDES= -I.
LIBS=-lcurses -lpthread -lm -lc


DEFINES= $(INCLUDES) $(DEFS) -DSYS_UNIX=1
CFLAGS= -g $(DEFINES)

SRCS = control.c serialglue.c actuator.c ahrs_qekf.c ahrs_quat_fast_ekf.c aircraft.c common.c main.c navigation.c networkglue.c robostix_acquisition.c sensor_acquisition.c telemetry.c tilt.c x-plane_acquisition.c rcrx.c pid_controller.c mission.c
OBJS = actuator.o serialglue.o ahrs_qekf.o ahrs_quat_fast_ekf.o aircraft.o common.o main.o navigation.o networkglue.o robostix_acquisition.o sensor_acquisition.o telemetry.o tilt.o x-plane_acquisition.o control.o rcrx.o pid_controller.o mission.o

.c.o:
	$(rm) $@
	$(CC) $(CFLAGS) -c $*.c

all: $(PROGNAME)

$(PROGNAME) : $(OBJS)
	$(CC) $(CFLAGS) -o $(PROGNAME) $(OBJS) $(LIBS)
	$(rm) $(OBJS)

clean:
	$(rm) $(OBJS) $(PROGNAME) core *~
