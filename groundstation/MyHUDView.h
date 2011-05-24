/* MyHUDView */

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <GLUT/GLUT.h>

#define kHUDOverlayColor 0
#define kIndicatorsOverlayColor 1
#define _red 0
#define _green 1
#define _blue 2
#define _alpha 3

#define DEG2RAD 0.01745328
#define _greenLimit 270
#define _yellowLimit 300

@interface MyHUDView : NSOpenGLView
{
	int						colorBits, depthBits;
	NSDictionary			*originalDisplayMode;
	GLuint					textures[2];
	GLenum					texFormat[2];   // Format of texture (GL_RGB, GL_RGBA)
	NSSize					texSize[2];
	char					*texBytes[2];
	unsigned char			*picPointer;
	float					roll,
							pitch,
							throttle,
							throttleAngle,
							latitude,
							longitude,
							airspeed,
							groundspeed,
							pressAltitude,
							gpsAltitude,
							radarAltitude,
							heading,
							desired_state[3];
	BOOL					gotTextures;
    float                   overlayColors[2][4];
}

- (id)initWithFrame:(NSRect)frame colorBits:(int)numColorBits depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;

- (void)reshape;
- (void)drawRect:(NSRect)rect;
- (void)setPicPointer:(unsigned char*)picPointer;
- (void)setRoll:(float)newRoll;
- (void)setPitch:(float)newPitch;
- (void)setThrottle:(float)newThrottle;
- (void)setLatitude:(float)newLatitude;
- (void)setLongitude:(float)newLongitude;
- (void)setAirspeed:(float)newAirspeed;
- (void)setGroundspeed:(float)newGroundspeed;
- (void)setPressAltitude:(float)newPressAltitude;
- (void)setGpsAltitude:(float)newGpsAltitude;
- (void)setRadarAltitude:(float)newRadarAltitude;
- (void)setHeading:(float)newHeading;
- (void)setDesiredState:(float *)newState;
- (void)setOverlayColorAtIndex: (int)index toColor:(float[4])newColor;

- (BOOL)loadGLTextures;

void drawStrAtPos2f(float x, float y, char *text);
void drawCircleAtPos3f(float x, float y, float z, float radius);
void drawFilledArc(float radius, int steps);
void drawArtificialHorizon(float roll, float pitch);

@end
