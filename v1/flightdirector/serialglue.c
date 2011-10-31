/*
 *  serialglue.c
 *  
 *
 *  Created by Filipe Varela on 08/04/07.
 *  Copyright 2008 Filipe Varela. All rights reserved.
 *
 */

#include <fcntl.h> 
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <termios.h> 
#include <unistd.h>
#include <sys/time.h>
#include <sys/stat.h> 
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>

#include "serialglue.h"

int open_serial_port(char port[], int baud) {
    int fd;
    struct termios newtio;

    fd = open(port, O_RDWR | O_NOCTTY);
    if (fd == -1) {
        perror("opening serial port");
        return -1;
    }

    // save current settings
    tcgetattr(fd, &newtio);

    // apply our settings
    cfsetspeed(&newtio, baud);
    newtio.c_cflag |= (CLOCAL | CREAD);
    newtio.c_cflag &= ~PARENB;
    newtio.c_cflag &= ~CSTOPB;
    newtio.c_cflag &= ~CSIZE;
    newtio.c_cflag |= CS8;
    newtio.c_iflag |= (IGNPAR | IGNBRK);
    newtio.c_oflag = 0;
    newtio.c_iflag &= ~(IXON | IXOFF | IXANY);
    newtio.c_lflag = 0;

    tcflush(fd, TCIOFLUSH);
    tcsetattr(fd, TCSANOW, &newtio);

    return(fd);
}

int close_serial_port(int port) {
    return close(port);
}

