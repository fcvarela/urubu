#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "global.h"
#include "nmea.h"
#include "gps.h"
#include "uart2.h"
#include "rprintf.h"
#include "buffer.h"
#include "timer128.h"
#include "vt100.h"
#include "a2d.h"
#include "i2c.h"

// ADC CHANNELS
#define ULTRASOUND_ADC_CHANNEL 1
#define STATICPRESS_ADC_CHANNEL 2
#define DYNAMICPRESS_ADC_CHANNEL 3

// GPS PACKET
typedef struct {
	double time;
	long satelites;
	double latitude;
	double longitude;
	double altitude;
} gpsPacketStruct;

extern GpsInfoType GpsInfo;
u08 headingH,headingL;
unsigned char ultrasound;
unsigned short spressure,dpressure;
gpsPacketStruct gpsPacket;

void getCompassHeading( void );

int main(void){
	char				*gpsPacketPointer;
	int					i;
	
	// INITIALIZE HARDWARE UARTS
	uartInit();
	
    // SET UART BAUD RATE
	uartSetBaudRate(0,115200); //Main comm to gumstix
	uartSetBaudRate(1,4800); //gps
    
	// Init timer
    timerInit();
		
	// Init console
    vt100Init();
	
	// Init ADC
	a2dInit();
	
    // Print boot message
    vt100ClearScreen();
    rprintf("\r\nURUBU ACQUISITION AND CONTROL MODULE INIT\r\n");
    rprintf("\r\nWILL SAMPLE SENSORS\r\n\r\n");
    
    /* operation:
        sample gps buffer. got packet? send
        sample sensors. send
    */
	
	while(1) {
		//check for gps packet. if true, update local variables
		if (nmeaProcess(uartGetRxBuffer(1))) {
			gpsPacket.time = GpsInfo.PosLLA.TimeOfFix.f;
			gpsPacket.satelites = GpsInfo.numSVs;
			gpsPacket.latitude = GpsInfo.PosLLA.lat.f;
			gpsPacket.longitude = GpsInfo.PosLLA.lon.f;
			gpsPacket.altitude = GpsInfo.PosLLA.alt.f;
        }
        
        // got a valid gps packet. write it out
        uartSendByte(0, 'B');
        gpsPacketPointer = (char *)&gpsPacket;
        for(i = sizeof(gpsPacket)-1; i >= 0; i--)
            uartSendByte(0, *(gpsPacketPointer+i));
			
		//check ultrasound altimeter (short range) data
        ultrasound = a2dConvert8bit(ULTRASOUND_ADC_CHANNEL);

        //check static pressure sensor
        spressure = a2dConvert10bit(STATICPRESS_ADC_CHANNEL);
			
        //check dynamic pressure sensor
        dpressure = a2dConvert10bit(DYNAMICPRESS_ADC_CHANNEL);
		
        //get compass heading
        getCompassHeading();
			
        //write ultrasound value
        uartSendByte(0, ultrasound);
			
        //write compass heading value
        uartSendByte(0, headingL);
        uartSendByte(0, headingH);
        
        //write footer
        uartSendByte(0,'Y');
	}
	
	return 0;
}

void getCompassHeading(){
	u08 CMPS03_ADDR = 0xC0;
	//u08 CMPS03_SOFTWARE_REVISION = 0x0;
	//u08 CMPS03_BEARING_BYTE = 0x1;
	u08 CMPS03_BEARING_WORD_HIGH = 0x2;
	u08 CMPS03_BEARING_WORD_LOW = 0x3;
	//u08 CMPS03_CALIBRATE_CMD = 0xF;
	
	i2cMasterSend(CMPS03_ADDR, 1, &CMPS03_BEARING_WORD_HIGH);
	i2cMasterReceive(CMPS03_ADDR, 1, &headingH);
	
	i2cMasterSend(CMPS03_ADDR, 1, &CMPS03_BEARING_WORD_LOW);
	i2cMasterReceive(CMPS03_ADDR, 1, &headingL);
}
