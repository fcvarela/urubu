/*
 *  mission.c
 *  
 *
 *  Created by Filipe Varela on 08/03/24.
 *  Copyright 2008 Filipe Varela. All rights reserved.
 *
 */

#include <string.h>
#include <stdlib.h>
#include "mission.h"

mission_t *mission;

mission_t * mission_init(void) {
    mission_t *m = malloc(sizeof(mission_t));
    memset(m, 0, sizeof(mission_t));
    return m;
}

void mission_add_waypoint(mission_t *m, waypoint_t wp) {
    waypoint_t *new_wp = malloc(sizeof(waypoint_t));
    memcpy(new_wp, &wp, sizeof(waypoint_t));

    new_wp->next = NULL;

    if (!m->next)
        m->next = new_wp;
    else
        m->last->next = new_wp;

    m->last = new_wp;
}

void mission_cleanup(mission_t *m) {
    waypoint_t *first, *temp;
    int i = 0;
    if (m == NULL)
        return;

    first = m->next;
    while (first != NULL) {
        temp = first->next;
        free(first);
        i++;
        first = temp;
    }
    free(m);
}
