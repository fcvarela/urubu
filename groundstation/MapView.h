/* MapView */

#import <Cocoa/Cocoa.h>

@interface MapView : NSView
{
	NSScroller *scroller;
	
	NSImage *backgroundImage;
	NSData *backgroundImageData;
	NSMutableArray *myPoints;
    NSMutableArray *specificPoints;
	NSMutableDictionary *baseCoordinates;
    
    int observationStartPoint,numberOfAircraft,observationWidth,cameraAperture;
	
	NSPoint tempCoords,mousePoint,aircraftPoint[4];
	id draggedObj,tempObj,doubleClickedObj;
    int selectedIndex;
	float clickInLineIndex,draggedObjIndex,zoomLevel;
	float aircraftHeading[4];
	float desiredHeading[4];
    IBOutlet id latitudeField,longitudeField,altitudeField,airspeedField,editWaypointPanel;
}

- (NSData *)returnImageData;

- (IBAction)orderInsertWaypointFromMenu:(id)sender;
- (IBAction)orderDeleteWaypointFromMenu:(id)sender;
- (IBAction)orderEditWaypointFromMenu:(id)sender;
- (IBAction)closeWaypointEditPanel:(id)sender;

- (id)initWithFrame:(NSRect)frameRect;
- (void)drawRect:(NSRect)rect;

- (void)setCursorPoint:(NSPoint)thePoint;
- (void)setAircraftPoint:(NSPoint)thePoint heading: (float)newHeading desiredHeading:(float)newDesiredHeading forAddress:(int)uav;
- (void)drawCursorPath;
- (void)drawAircraftPath;

- (void)replotWaypointsWithRect:(NSRect)rect;
- (void)setPoints:(NSMutableArray *)thePoints;
- (NSMutableArray *)GPSPoints;
- (void)setBaseCoordinates:(NSMutableDictionary *)theCoords;
- (void)setObservationWidth:(NSNumber *)theWidth;
- (void)setNumberOfAircraft:(NSNumber *)theNumber;
- (void)setObservationStartPoint:(NSNumber *)thePoint;
- (void)setCameraAperture:(NSNumber *)theNumber;
- (void)setBackgroundImageData:(NSData *)theImageData;
- (float)distanceToLine:(NSPoint)thePoint linePointOne:(NSPoint)linePointOne linePointTwo:(NSPoint)linePointTwo;
- (float)magnitude:(NSPoint)point1 point2:(NSPoint)point2;
- (void)orderInsertWaypointInLine:(int)atIndex;
- (NSPoint)gpsCoordinatesFromPoint:(NSPoint)thePoint;
- (NSPoint)pointCoordinatesFromGps:(NSPoint)thePoint;
- (float)distanceInMetersFromLatitude:(float)latitude longitude:(float)longitude toLatitude:(float)destLatitude toLongitude:(float)destLongitude;

- (void)zoomIn:(id)sender;
- (void)zoomOut:(id)sender;
- (float)zoomLevel;

@end
