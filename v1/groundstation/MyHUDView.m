#import "MyHUDView.h"

@interface MyHUDView (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (BOOL) initGL;
@end

@implementation MyHUDView

#pragma mark - INIT
- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
	NSOpenGLPixelFormat *pixelFormat;

	colorBits = numColorBits;
	depthBits = numDepthBits;
	
	pixelFormat = [self createPixelFormat:frame];
	if( pixelFormat != nil )
	{
		self = [super initWithFrame:frame pixelFormat:pixelFormat];
		[pixelFormat release];
		
		if( self ){
			[[self openGLContext] makeCurrentContext];
			[self reshape];
			
			if( ![self initGL] ){
				[self clearGLContext];
				self = nil;
			}
		}
	}
	else
		self = nil;
	
	glGenTextures( 1, &textures[0]);
	gotTextures = NO;
	picPointer = 0;
	roll = 0;
	pitch = 0;
	throttle = 0;
	throttleAngle = 270;
	
	return self;
}

- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute pixelAttribs[16];
	int pixNum = 0;
	NSOpenGLPixelFormat *pixelFormat;

	pixelAttribs[pixNum++] = NSOpenGLPFADoubleBuffer;
	pixelAttribs[pixNum++] = NSOpenGLPFAAccelerated;
	pixelAttribs[pixNum++] = NSOpenGLPFAColorSize;
	pixelAttribs[pixNum++] = colorBits;
	pixelAttribs[pixNum++] = NSOpenGLPFADepthSize;
	pixelAttribs[pixNum++] = depthBits;/*
	pixelAttribs[pixNum++] = NSOpenGLPFAMultisample;
	pixelAttribs[pixNum++] = NSOpenGLPFASampleBuffers;
	pixelAttribs[pixNum++] = (NSOpenGLPixelFormatAttribute)1;
	pixelAttribs[pixNum++] = NSOpenGLPFASamples;
	pixelAttribs[pixNum++] = (NSOpenGLPixelFormatAttribute)2;
*/
	pixelAttribs[pixNum] = 0;
	pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelAttribs];

	return pixelFormat;
}


/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{ 		
	
	glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
	glEnable( GL_TEXTURE_2D );
	glLineWidth(2.0);
	glEnable( GL_LINE_SMOOTH );
	
	glDepthFunc( GL_LEQUAL );
	glEnable( GL_DEPTH_TEST );
	
	glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	
	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
	
	return TRUE;
}

#pragma mark - LOAD TEXTURES
- (BOOL) loadGLTextures
{
	BOOL			status = FALSE;
	int				bytesPRow=3*512;
	int				rowNum, destRowNum;
	
	texFormat[0]= GL_RGB;
		
	texSize[0].width = 512;
	texSize[0].height = 256;
	texBytes[0]= calloc( bytesPRow * texSize[0].height, 1 );
		
	if( texBytes[0]!= NULL )
	{
		destRowNum = 0;
		for( rowNum = texSize[0].height - 1; rowNum >= 0;rowNum--, destRowNum++ ){
			// Copy the entire row in one shot
			memcpy( texBytes[0] + ( destRowNum * bytesPRow ), picPointer + ( rowNum * bytesPRow ), bytesPRow );
		}
	}
	
	status = TRUE;
	glBindTexture( GL_TEXTURE_2D, textures[0]);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);	// Linear Filtering
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);	// Linear Filtering
	glTexImage2D( GL_TEXTURE_2D, 0, GL_RGB, texSize[0].width, texSize[0].height, 0, GL_RGB, GL_UNSIGNED_BYTE, texBytes[0]);
	free( texBytes[0] );
	gotTextures = YES;
	return status;
}

# pragma mark - RESHAPE
- (void) reshape
{ 
	NSRect sceneBounds;
	
	[[self openGLContext] update];
	sceneBounds = [self bounds];
	glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
	glMatrixMode( GL_PROJECTION );
	glLoadIdentity();
	gluPerspective( 45.0f, sceneBounds.size.width / sceneBounds.size.height, 0.1f, 10000.0f );
}


/* DRAW */
#pragma mark - REDRAW
- (void) drawRect:(NSRect)rect
{	
	char	tempStr[255];
		
	// Clear the screen and depth buffer
	glClearColor(0.5, 0.5, 0.5, 1.0);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	
	// But make sure we got a texture, otherwise we'll crash
	if(gotTextures){
		// Enable textures to draw our frame as background
		glEnable( GL_TEXTURE_2D );
		glBindTexture(GL_TEXTURE_2D, textures[0]);
		
		glBegin(GL_QUADS);
		// Front Face
		glColor4f(1.0f,1.0f,1.0f,1.0f);
		glTexCoord2f(000.0f, 000.0f); glVertex3f(-160.0f, -136.0f,  -290.0f);	// Bottom Left Of The Texture and Quad
		glTexCoord2f(001.0f, 000.0f); glVertex3f( 352.0f, -136.0f,  -290.0f);	// Bottom Right Of The Texture and Quad
		glTexCoord2f(001.0f, 001.0f); glVertex3f( 352.0f,  120.0f,  -290.0f);	// Top Right Of The Texture and Quad
		glTexCoord2f(000.0f, 001.0f); glVertex3f(-160.0f,  120.0f,  -290.0f);	// Top Left Of The Texture and Quad
		glEnd();
		
		//disable textures to draw the solid lines
		glDisable( GL_TEXTURE_2D );
	}
	
	glColor4f(overlayColors[kHUDOverlayColor][_red],
                      overlayColors[kHUDOverlayColor][_green],
                      overlayColors[kHUDOverlayColor][_blue],
                      overlayColors[kHUDOverlayColor][_alpha]);
	//this messes up the matrix
	drawArtificialHorizon(roll, pitch);
	
	//revert to indicator color (indicator = text)
	glColor4f(overlayColors[kIndicatorsOverlayColor][_red],
                  overlayColors[kIndicatorsOverlayColor][_green],
                  overlayColors[kIndicatorsOverlayColor][_blue],
                  overlayColors[kIndicatorsOverlayColor][_alpha]);
	
	//heading indicator (all 2 d)
	sprintf(tempStr, "%3.1f / %3.0f", heading, desired_state[0]);
	drawStrAtPos2f(-0.01, 0.4, tempStr);
	
	#pragma mark !throttle gauge
	// draw Throttle gauge
	drawCircleAtPos3f(120, -90, -290, 15.0f);
	
	glPushMatrix();
	glTranslatef(120, -90, -290);
	//draw needle origin to base vertex
	glLineWidth(3.0);
	glBegin(GL_LINES);
	glVertex2f(0.0f, 0.0f);
	glVertex2f(cos(270*DEG2RAD)*15,sin(270*DEG2RAD)*15);
	glEnd();
	
	// draw vertexes up to throttleAngle
	drawFilledArc(14.0f, throttleAngle);
	glPopMatrix();
	
	glColor4f(overlayColors[kIndicatorsOverlayColor][_red],
		overlayColors[kIndicatorsOverlayColor][_green],
        overlayColors[kIndicatorsOverlayColor][_blue],
        overlayColors[kIndicatorsOverlayColor][_alpha]);
	
	//heading indicator
	sprintf(tempStr, "Throttle: %3.1f", throttle);
	drawStrAtPos2f(0.35f, -0.44f, tempStr);
	
	//draw airspeed (middle left)
	sprintf(tempStr, "AS: %3.2f / %3.0f", airspeed, desired_state[2]);
	drawStrAtPos2f(-0.57f, 0.02f, tempStr);
	
	//draw groundspeed (middle left)
	sprintf(tempStr, "GS: %3.1f", groundspeed);
	drawStrAtPos2f(-0.57f, -0.04f, tempStr);
	
	//draw press alt (middle right)
	sprintf(tempStr, "ALT: %3.1f", gpsAltitude);
	drawStrAtPos2f(0.4f, 0.02f, tempStr);
	
	//draw radar alt (middle left)
	sprintf(tempStr, "RALT: %3.1f", radarAltitude);
	drawStrAtPos2f(0.375f, -0.04f, tempStr);

	//draw desired alt (middle left)
	sprintf(tempStr, "DALT: %3.0f", desired_state[1]);
	drawStrAtPos2f(0.371f, -0.10f, tempStr);
	
	//draw latitude (topleft)
	sprintf(tempStr, "Lat:  %3.5f", latitude);
	drawStrAtPos2f(-0.57f, 0.4f,tempStr);
	
	//draw longitude (topleft)
	sprintf(tempStr, "Lon: %3.5f", longitude);
	drawStrAtPos2f(-0.57f, 0.35f, tempStr);
	
	[[self openGLContext] flushBuffer];
}

#pragma mark - DRAW ELEMENTS
void drawCircleAtPos3f(float x, float y, float z, float radius)
{
	int		i;
	
	glPushMatrix();
	
	glTranslatef(x, y, z);
	glBegin(GL_LINES);
	
	for (i=0; i < 360; i++)
	{
		float degInRad = i*DEG2RAD;
		glVertex2f(cos(degInRad)*radius,sin(degInRad)*radius);
	}
	
	glEnd();
	
	glPopMatrix();
}

void drawFilledArc(float radius, int steps)
{
	GLfloat degInRad = 0.0f;
	int i;
	
	glLineWidth(2.0);
	glColor4f(0.0f,1.0f,0.0f,1.0f);
	
	glBegin(GL_POLYGON);
		glVertex2f(0.0f, 0.0f);
		glVertex2f(cos(270*DEG2RAD)*radius, sin(270*DEG2RAD)*radius);
	
		for (i=0; i<steps && i<=_greenLimit; i++) {
			degInRad = (270-i)*DEG2RAD;
			glVertex2f(cos(degInRad)*radius, sin(degInRad)*radius);
		}
		
		glVertex2f(0.0f, 0.0f);
	glEnd();
	
	if (steps > _greenLimit)
	{
		glColor4f(1.0f,1.0f,0.0f,1.0f);
		glBegin(GL_POLYGON);
		glVertex2f(0.0f, 0.0f);
		glVertex2f(cos(degInRad)*radius, sin(degInRad)*radius);
		
		for (; i<steps && i<=_yellowLimit; i++) {
			degInRad = (270-i)*DEG2RAD;
			glVertex2f(cos(degInRad)*radius, sin(degInRad)*radius);
		}
		
		glVertex2f(0.0f, 0.0f);
		glEnd();
	}
	
	if (steps > _yellowLimit) {
		glColor4f(1.0f,0.0f,0.0f,1.0f);
		glBegin(GL_POLYGON);
		glVertex2f(0.0f, 0.0f);
		glVertex2f(cos(degInRad)*radius, sin(degInRad)*radius);
		
		for (; i<steps; i++) {
			degInRad = (270-i)*DEG2RAD;
			glVertex2f(cos(degInRad)*radius, sin(degInRad)*radius);
		}
		glVertex2f(0.0f, 0.0f);
		glEnd();
	}
}

void drawStrAtPos2f(float x, float y, char *text)
{
	char *p;
	
	glPushMatrix();
	
	glRasterPos3f(x, y, -1.1f);
	
	for (p = text; *p; p++){
		//glutStrokeCharacter(GLUT_STROKE_ROMAN, *p);
		glutBitmapCharacter(GLUT_BITMAP_HELVETICA_10, *p);
	}
	
	glPopMatrix();
}

void drawArtificialHorizon(float roll, float pitch)
{
	int i,halfLength;
	char tempStr[50];
					  
	glPushMatrix();
	
	glRotatef(roll,0,0,1);
	glRotatef(-pitch,1,0,0);
	
	for(i=0;i<=355;i+=5){
		if(i==0 || i==180)
			halfLength = -160;
		else {
			if(i%2 == 0){
				halfLength = -40;
			}
			else
				halfLength = -20;
		}
		
		glBegin(GL_LINES);
			glVertex3f(-halfLength,0.0f,-289.9f);
			glVertex3f( halfLength,0.0f,-289.9f);
		glEnd();
		
		//draw angle reference
		glTranslatef(0,0,-1.1f);
        
		//correct string
		sprintf(tempStr, "%3.0f", asin(sin(i*0.0174532925199433))/0.0174532925199433);
		drawStrAtPos2f(0.0,0.0,tempStr);
		glTranslatef(0,0,1.1f);
		
		glRotatef(5,1,0,0);
	}
	
	glPopMatrix();
}

#pragma mark - ACCESSORS

- (void)setRoll:(float)newRoll
{
	roll = newRoll;
}

- (void)setPitch:(float)newPitch
{
	pitch = newPitch;
}

- (void)setThrottle:(float)newThrottle;
{
	throttle = newThrottle;
	// 0-255 -> 0-360
	
	throttleAngle = throttle / 100 * 360;
}

- (void)setLatitude:(float)newLatitude
{
	latitude = newLatitude;
}

- (void)setLongitude:(float)newLongitude
{
	longitude = newLongitude;
}

- (void)setAirspeed:(float)newAirspeed
{
	airspeed = newAirspeed;
}

- (void)setGroundspeed:(float)newGroundspeed
{
	groundspeed = newGroundspeed;
}

- (void)setPressAltitude:(float)newPressAltitude
{
	pressAltitude = newPressAltitude;
}

- (void)setGpsAltitude:(float)newGpsAltitude
{
	gpsAltitude = newGpsAltitude;
}

- (void)setRadarAltitude:(float)newRadarAltitude
{
	radarAltitude = newRadarAltitude;
}

- (void)setHeading:(float)newHeading
{
	heading = newHeading;
}

- (void)setPicPointer:(unsigned char *)newPointer
{
	picPointer = newPointer;
}

- (void)setOverlayColorAtIndex: (int)index toColor:(float[4])newColor
{
    overlayColors[index][0] = newColor[0];
    overlayColors[index][1] = newColor[1];
    overlayColors[index][2] = newColor[2];
    overlayColors[index][3] = newColor[3];	
}

- (void)setDesiredState:(float *)newState
{
	desired_state[0] = newState[0];
	desired_state[1] = newState[1];
	desired_state[2] = newState[2];
}

@end
