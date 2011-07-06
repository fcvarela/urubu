#!/bin/bash
CC="g++"
LD="g++"
AR="ar -crs"
SIZE="size"
LIBS+="-lGL -lGLU"

g++ -I./ -ISDK/XPLM -ISDK/Widgets -I/usr/include/ -DIBM=0 -DAPL=0 -DLIN=1 -O0 -x c++ -ansi -c -fPIC EngineStarter.cpp -o EngineStarter.o
g++ -shared ${LDFLAGS} -o EngineStarter.xpl EngineStarter.o ${LIBS}

