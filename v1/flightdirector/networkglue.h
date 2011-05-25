/*
 *  networkglue.h
 *  
 *
 *  Created by Filipe Varela on 06/12/14.
 *  Copyright 2006 Filipe Varela. All rights reserved.
 *
 */

// output data (status)
#define TELEMETRY_UDP_PORT 1235

// receive control packets
#define CONTROL_UDP_PORT 1236

#define XPLANE_UDP_PORT 50000
#define XPLANECTRL_UDP_PORT 49000 /* control in simulated env */

int network_make_sockets(void);
int network_read_robostix(void *read_into, size_t len);
int network_read_xplane(void *read_into, size_t len);
int network_write_xplane(void *read_into, size_t len);
int network_write_telemetry(void *read_from, size_t len);
int network_read_control(void *read_into, size_t len);
int network_read_mission(void);
