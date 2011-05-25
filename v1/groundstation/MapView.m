#import "MapView.h"

#define ZOOMINFACTOR   (2.0)
#define ZOOMOUTFACTOR  (1.0 / ZOOMINFACTOR)

@implementation MapView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil) {
		myPoints = [[NSMutableArray alloc] init];
		
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil]];
		zoomLevel = 1.0;
        numberOfAircraft = 1;
        observationWidth = 1;
        observationStartPoint = 0;
	}
	return self;
}

- (void)zoomIn:(id)sender
{
    NSRect tempRect;
    NSRect oldBounds;
    NSScrollView *scrollView = [self enclosingScrollView];
	
    oldBounds = [self bounds];
	
    tempRect = [self frame];
    tempRect.size.width = ZOOMINFACTOR * NSWidth(tempRect);
    tempRect.size.height = ZOOMINFACTOR * NSHeight(tempRect);
    [self setFrame:tempRect];
	
    [self setBoundsSize:oldBounds.size];
    [self setBoundsOrigin:oldBounds.origin];
	
	//reset line width
	zoomLevel*=ZOOMINFACTOR;
    NSLog(@"Set zoom level to %d", zoomLevel);
	[NSBezierPath setDefaultLineWidth: 1.0/zoomLevel];
    
    if (scrollView) [scrollView setNeedsDisplay:YES];
    else [[self superview] setNeedsDisplay:YES];
	
    return;
}


- (void)zoomOut:(id)sender
{
    NSRect tempRect;
    NSRect oldBounds;
    NSScrollView *scrollView = [self enclosingScrollView];
	
    oldBounds = [self bounds];
	
    tempRect = [self frame];
    tempRect.size.width = ZOOMOUTFACTOR * NSWidth(tempRect);
    tempRect.size.height = ZOOMOUTFACTOR * NSHeight(tempRect);
    [self setFrame:tempRect];
	
    [self setBoundsSize:oldBounds.size];
    [self setBoundsOrigin:oldBounds.origin];
	
	//reset line width
	zoomLevel*=ZOOMOUTFACTOR;
    NSLog(@"Set zoom level from %d to %d", zoomLevel);
	[NSBezierPath setDefaultLineWidth: 1.0/zoomLevel];
	
    if (scrollView) [scrollView setNeedsDisplay:YES];
    else [[self superview] setNeedsDisplay:YES];
	
    return;
}

- (void)resetCursorRects
{
	[self addCursorRect:[self visibleRect] cursor: [NSCursor crosshairCursor]];
}

- (void)dealloc
{
    [self unregisterDraggedTypes];
    [super dealloc];
}

- (NSData *)returnImageData
{
		return backgroundImageData;
}

- (void)setPoints:(NSMutableArray *)thePoints
{
	[thePoints retain];
	[myPoints release];
	myPoints = thePoints;
	[self setNeedsDisplay: TRUE];
}

- (void)setBaseCoordinates:(NSMutableDictionary *)theCoords
{
	[theCoords retain];
	[baseCoordinates release];
	baseCoordinates = theCoords;
}

- (void)setBackgroundImageData:(NSData *)theImageData
{
	[theImageData retain];
	[backgroundImageData release];
	backgroundImageData = [[NSData alloc] initWithData: theImageData];
	
	[backgroundImage release];
	backgroundImage = [[NSImage alloc] initWithData: theImageData];
	
	[self setFrameSize: [backgroundImage size]];
	[self setNeedsDisplay: TRUE];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent{
	id obj;
	int x, y, prevX, prevY, index;
	float distance;
	
	index = prevX = prevY = 0;
	//clicked a waypoint? show waypoint menu

	NSPoint pt = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	NSEnumerator *en = [myPoints objectEnumerator];	

	tempCoords = pt;

	while ( (obj=[en nextObject]) ){
		tempObj = nil;
		
		x = [[obj valueForKey:@"x"] intValue];
		y = [[obj valueForKey:@"y"] intValue];
		
		//calculate distance between clickpoint and waypoint
		if (sqrt( ((pt.x-x)*(pt.x-x)) + ((pt.y-y)*(pt.y-y)) ) <= 10)
		{
			//we got a right click in a waypoint... allow delete
			tempObj = obj;
			return [self menu];
		}
		else
		{
			distance=[self distanceToLine:pt linePointOne: NSMakePoint(x,y) linePointTwo: NSMakePoint(prevX,prevY)];
			if (prevX>0 && distance>=0 && distance<=3){
				clickInLineIndex = index;
				[self orderInsertWaypointInLine: index];
				//set tempcoords = intersect... or not
				return nil;
			}
		}
		
		prevX = x; prevY = y;
		index++;
	}
	
	return [self menu];
}

- (void)drawRect:(NSRect)rect
{
	[backgroundImage drawInRect: rect fromRect: rect operation:NSCompositeSourceOver fraction: 1.0];
    /*
		NSMakeRect(0,0,[backgroundImage size].width,[backgroundImage size].height)
						fromRect:
		NSMakeRect(0,0,[backgroundImage size].width,[backgroundImage size].height)
		operation:NSCompositeSourceOver fraction:1.0];*/
			
	[self replotWaypointsWithRect: rect];
}

- (void)mouseEntered:(NSEvent *)theEvent{
	[[self window] setAcceptsMouseMovedEvents:YES];
	[[self window] makeFirstResponder:self];
}

- (void)mouseExited:(NSEvent *)theEvent{
	[[self window] setAcceptsMouseMovedEvents:NO];
}

- (void)mouseDown:(NSEvent *)theEvent{
	id				obj;
	int				x,y;
	int				i;
	
	i=0;
	
	NSPoint pt = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	
	//reset draggedObj;
	draggedObj = nil;
	
	NSEnumerator *en = [myPoints objectEnumerator];
	while( (obj=[en nextObject]) )
	{
		x = [[obj valueForKey:@"x"] intValue];
		y = [[obj valueForKey:@"y"] intValue];
		
		//calculate distance
		if(sqrt( ((pt.x-x)*(pt.x-x)) + ((pt.y-y)*(pt.y-y)) ) <= 10){
			//we got a hit. allow drag
			draggedObj = obj;
			draggedObjIndex=i;
		}
		i++;
	}
	
}

- (void)mouseUp:(NSEvent *)theEvent
{
	id				obj;
	int				x,y;
	int				i;
	
	i=0;
	
	if([theEvent clickCount]<2 && draggedObj) {
        [self setNeedsDisplay: YES];
        draggedObj = nil;
		return;
	}
    
	NSPoint pt = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	
    //reset draggedObj;
	doubleClickedObj = nil;
	
	//start enumerator.
	NSEnumerator *en = [myPoints objectEnumerator];
	while ((obj=[en nextObject]))
	{
		x = [[obj valueForKey:@"x"] intValue];
		y = [[obj valueForKey:@"y"] intValue];
		
		//calculate distance
		if(sqrt( ((pt.x-x)*(pt.x-x)) + ((pt.y-y)*(pt.y-y)) ) <= 10){
			//we got a hit. tag for edit
			doubleClickedObj = obj;
			
            // get current point data
            NSPoint gpsCoords = [self gpsCoordinatesFromPoint:NSMakePoint(x,y)];
            float altitude = [[obj valueForKey:@"alt"] floatValue];
            float airspeed = [[obj valueForKey:@"airspeed"] floatValue];
                        
            // fill in fields with data of item at pos i
            [latitudeField setStringValue: [NSString localizedStringWithFormat: @"%3.8f", gpsCoords.y]];
            [longitudeField setStringValue: [NSString localizedStringWithFormat: @"%3.8f", gpsCoords.x]];
            [altitudeField setStringValue: [NSString localizedStringWithFormat: @"%3.8f", altitude]];
            [airspeedField setStringValue: [NSString localizedStringWithFormat: @"%3.8f", airspeed]];
            
            // changing the selection index should change the fields as well
            
            // trigger the panel
            [NSApp beginSheet: editWaypointPanel modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(editWaypointPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
		
		// increment
		i++;
	}
}

- (IBAction)closeWaypointEditPanel:(id)sender
{
    if ([[sender title] isEqualToString:@"OK"]) {
        // save...y is latitude, x is longitude
        NSNumber *latitude = [NSNumber numberWithFloat: [latitudeField floatValue]];
        NSNumber *longitude = [NSNumber numberWithFloat: [longitudeField floatValue]];
        NSNumber *altitude = [NSNumber numberWithFloat: [altitudeField floatValue]];
        NSNumber *airspeed = [NSNumber numberWithFloat: [airspeedField floatValue]];
        
        NSLog(@"latitude: %@", [latitude stringValue]);
        NSPoint localPoint = [self pointCoordinatesFromGps:NSMakePoint([longitude floatValue], [latitude floatValue])];
        
        [doubleClickedObj setValue: [NSString stringWithFormat: @"%f", localPoint.y] forKey: @"y"];
        [doubleClickedObj setValue: [NSString stringWithFormat: @"%f", localPoint.x] forKey: @"x"];
        [doubleClickedObj setValue: [altitude stringValue] forKey: @"alt"];
        [doubleClickedObj setValue: [airspeed stringValue] forKey: @"airspeed"];
        
    }
        
    [NSApp endSheet: editWaypointPanel];
}

- (void)editWaypointPanelDidEnd:theSheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [theSheet orderOut:self];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint pt;
	
	pt = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	
	//do we have a draggedObj? drop it here
	if (draggedObj) {
        mousePoint = pt;
        NSString *x = [[NSNumber numberWithInt: pt.x] stringValue];
		NSString *y = [[NSNumber numberWithInt: pt.y] stringValue];

		[draggedObj setObject: x forKey: @"x"];
		[draggedObj setObject: y forKey: @"y"];
        [self setNeedsDisplayInRect: [self visibleRect]];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	if([menuItem action]==@selector(orderDeleteWaypointFromMenu:) && tempObj)
		return true;
	
	if([menuItem action]==@selector(orderInsertWaypointFromMenu:) && !tempObj)
		return true;
    
    if([menuItem action]==@selector(orderEditWaypointFromMenu:) && tempObj)
        return true;
    
	return false;
}

- (IBAction)orderDeleteWaypointFromMenu:(id)sender
{
	[myPoints removeObject:tempObj];
	[self setNeedsDisplay: TRUE];
	tempObj = nil;
}

- (IBAction)orderInsertWaypointFromMenu:(id)sender
{
	NSMutableDictionary *record = [[NSMutableDictionary alloc] init];
	
	[record setObject:[[NSNumber numberWithInt: tempCoords.x] stringValue] forKey:@"x"];
	[record setObject:[[NSNumber numberWithInt: tempCoords.y] stringValue] forKey:@"y"];
	[record setObject:[[NSNumber numberWithInt: 0] stringValue] forKey:@"alt"];
    [record setObject:[[NSNumber numberWithInt: 0] stringValue] forKey:@"airspeed"];
	
	[myPoints insertObject:record atIndex:[myPoints count]];
	[self setNeedsDisplay: TRUE];
}

- (IBAction)orderEditWaypointFromMenu:(id)sender
{
    NSBeep();
	NSBeep();
}

- (void)orderInsertWaypointInLine:(int)atIndex
{
	NSMutableDictionary *record = [[NSMutableDictionary alloc] init];
	
	[record setObject:[[NSNumber numberWithInt: tempCoords.x] stringValue] forKey:@"x"];
	[record setObject:[[NSNumber numberWithInt: tempCoords.y] stringValue] forKey:@"y"];
	[record setObject:[[NSNumber numberWithInt: 0] stringValue] forKey:@"alt"];
    [record setObject:[[NSNumber numberWithInt: 0] stringValue] forKey:@"airspeed"];
	
	[myPoints insertObject:record atIndex:atIndex];
	[self setNeedsDisplay: TRUE];
}

- (NSMutableArray *)GPSPoints
{
    NSMutableArray *gpsPoints = [NSMutableArray arrayWithCapacity:1];
    
    id obj;
    int i = 0;
    
    NSLog(@"Original waypoint array has %d items", [myPoints count]);
    for (i=0; (unsigned)i<[myPoints count]; i++) {
        if (i == observationStartPoint || i == observationStartPoint+1)
            continue;
        
        obj = [myPoints objectAtIndex: i];
        NSPoint pt = NSMakePoint([[obj valueForKey:@"x"] floatValue], [[obj valueForKey:@"y"]floatValue]);
        NSPoint GPSpt = [self gpsCoordinatesFromPoint:pt];
        [gpsPoints addObject:
            [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                [NSNumber numberWithFloat: GPSpt.x], @"x",
                [NSNumber numberWithFloat: GPSpt.y], @"y",
                [NSNumber numberWithFloat: [[obj valueForKey:@"alt"] floatValue]], @"alt",
                [NSNumber numberWithFloat: [[obj valueForKey:@"airspeed"] floatValue]], @"airspeed",
                [NSNumber numberWithFloat: -1.0], @"uavindex",
                nil]];
        NSLog(@"Inserted original point");
    }
    
    // append specific points at right position
    for (i = 0; (unsigned)i<[specificPoints count]; i++) {
        obj = [specificPoints objectAtIndex: i];
        NSPoint pt = NSMakePoint([[obj valueForKey:@"x"] floatValue], [[obj valueForKey:@"y"]floatValue]);
        NSPoint GPSpt = [self gpsCoordinatesFromPoint:pt];
        [gpsPoints insertObject:
            [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                [NSNumber numberWithFloat: GPSpt.x], @"x",
                [NSNumber numberWithFloat: GPSpt.y], @"y",
                [NSNumber numberWithFloat: [[obj valueForKey:@"alt"] floatValue]], @"alt",
                [NSNumber numberWithFloat: [[obj valueForKey:@"airspeed"] floatValue]], @"airspeed",
                [NSNumber numberWithFloat: [[obj valueForKey:@"uavindex"] floatValue]], @"uavindex",
                nil] atIndex: i+observationStartPoint];
            NSLog(@"Inserted specific point for uav: %f", [[obj valueForKey:@"uavindex"] floatValue]);
    }
    
    NSLog(@"%@", gpsPoints);
        
    return gpsPoints;
}

- (void)replotWaypointsWithRect:(NSRect)rect
{
	id				obj;
	int				x,y,i;
	
	i=0;
    float DEG2RAD = 3.14159/180;
	
	NSBezierPath *mission = [NSBezierPath bezierPath];
	NSEnumerator *en = [myPoints objectEnumerator];
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

	while ((obj=[en nextObject])) {
		x = [[obj valueForKey:@"x"] intValue];
		y = [[obj valueForKey:@"y"] intValue];

        //read coords in px and redraw them on the view
		NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x-(7/zoomLevel),y-(7/zoomLevel),14/zoomLevel,14/zoomLevel)];		
        if( [defs dataForKey:@"routePlotColor"] )
            [[NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routePlotColor"]] set];
        
        [dot fill];
        [[NSColor blackColor] set];
        [dot stroke];
        
        if(i>0)
            [mission lineToPoint: NSMakePoint(x, y)];
        else
            [mission moveToPoint: NSMakePoint(x,y)];
        i++;
    }
	
	if([defs dataForKey:@"routePlotColor"])
		[[NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routePlotColor"]] set];
        
	[mission stroke];
	
	en = nil;
	i=0;
	en = [myPoints objectEnumerator];
	
	while ((obj=[en nextObject])) {
		x = [[obj valueForKey:@"x"] intValue];
		y = [[obj valueForKey:@"y"] intValue];
		
		//desenhar labels feito a parte porque o stroke do mission cobre o numero
		NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
		if([defs dataForKey:@"routeLabelColor"])
			[attribs setObject: [NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routeLabelColor"]] forKey:NSForegroundColorAttributeName];
		if([NSFont fontWithName:@"Lucida Sans" size: 9/zoomLevel])
			[attribs setObject: [NSFont fontWithName:@"Lucida Sans" size: 9/zoomLevel] forKey:NSFontAttributeName];
		NSString *number = [NSString stringWithFormat: @"%d", i];
		[number drawAtPoint: NSMakePoint(x,y) withAttributes:attribs];
		i++;
	}
	
	[self drawAircraftPath];
    
    // draw observation area
    if (observationStartPoint > 0 && observationWidth > 1) {
        // encontrar ponto de inicio e fim
        id sPoint = [myPoints objectAtIndex: observationStartPoint];
        id ePoint = [myPoints objectAtIndex: observationStartPoint+1];
        float height = [[sPoint valueForKey:@"alt"] floatValue];
        NSPoint startPoint = NSMakePoint([[sPoint valueForKey:@"x"] intValue],[[sPoint valueForKey:@"y"] intValue]);
        NSPoint endPoint = NSMakePoint([[ePoint valueForKey:@"x"] intValue],[[ePoint valueForKey:@"y"] intValue]);
        
        // determinar declive de start para end
        float declive = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
        
        // declive da-me o angulo
        float angulo = atan(declive);
        
        // encontrar os dois pontos com afastamento width/2 do ponto inicial e cujos
        // angulos sao angulo+90 e angulo-90
        float ang1 = angulo + ((float)pi/2.0);
        
        // criar recta que marca inicio da area de vigilancia
        NSPoint point1 = NSMakePoint(startPoint.x + cos(ang1) * (observationWidth/2), startPoint.y + sin(ang1) * (observationWidth/2));
        NSPoint point2 = NSMakePoint(startPoint.x - cos(ang1) * (observationWidth/2), startPoint.y - sin(ang1) * (observationWidth/2));
        
        // e a marca de fim
        NSPoint point3 = NSMakePoint(endPoint.x + cos(ang1) * (observationWidth/2), endPoint.y + sin(ang1) * (observationWidth/2));
        NSPoint point4 = NSMakePoint(endPoint.x - cos(ang1) * (observationWidth/2), endPoint.y - sin(ang1) * (observationWidth/2));
        
        [NSBezierPath strokeLineFromPoint:point1 toPoint:point2];
        [NSBezierPath strokeLineFromPoint:point3 toPoint:point4];
        
        // desenhar as bandas monitorizadas por cada robot
        int aircraftZone = observationWidth / numberOfAircraft;
        
        // preparar holder dos pontos de cada robot dentro da zona a monitorizar
        // criar specific points com alt, pontos e index de aircraft
        if (specificPoints != nil)
            [specificPoints release];
        specificPoints = [[NSMutableArray alloc] initWithCapacity:1];
        
        for (i=0; i<=numberOfAircraft; i++) {
            [[NSColor greenColor] set];
            // dividir observationWidth por numero de robots
            // para cada ponto na linha perpendicular a que liga origem a destino
            // calcular a sua posicao desde startpoint - cos(ang1) * aircraftZone ate startPoint + cos(ang1) * aircraftZone
            point1 = NSMakePoint(
                startPoint.x - cos(ang1) * observationWidth/2 + aircraftZone * cos(ang1) * i,
                startPoint.y - sin(ang1) * observationWidth/2 + aircraftZone * sin(ang1) * i);
            point2 = NSMakePoint(
                endPoint.x - cos(ang1) * observationWidth/2 + aircraftZone * cos(ang1) * i,
                endPoint.y - sin(ang1) * observationWidth/2 + aircraftZone * sin(ang1) * i);

            [NSBezierPath strokeLineFromPoint: point1 toPoint: point2];
            
            // para cada aviao, desenhar rota seguida dentro da area
            // 1 - Converter point1 para GPS, calcular afastamento em pes
            // 2 - Converter altura em pes para pixels com base na escala de point1
            float distancePixels = sqrt(pow(point1.x-point2.x,2) + pow(point1.y-point2.y,2));
            NSPoint gpsPoint1 = [self gpsCoordinatesFromPoint: point1];
            NSPoint gpsPoint2 = [self gpsCoordinatesFromPoint: point2];
            float distanceGPS = [self distanceInMetersFromLatitude:gpsPoint1.y longitude:gpsPoint1.x toLatitude:gpsPoint2.y toLongitude:gpsPoint2.x];
            
            // metros por pixel
            float metersPerPixel = distanceGPS / distancePixels;
            
            // pes por pixel
            float feetPerPixel = 3.2808 * metersPerPixel;
            
            // how many pixels is height in feet?
            float heightPixels = height / feetPerPixel;
            
            // utilizar heightPixels para calcular diametro area observada
            float visibleWidth = heightPixels * tanf((float)cameraAperture*DEG2RAD) * 2.0;
            
            // pintar circulo visivel no ponto inicial deste UAV:+------+ -> viragem..
            //                                               fim +------+ <- entra
            
            // temos point 1 e point2: UAV e viragem inicial. adicionar offsets de visibleWidth ate perfazer total da area: dist point1 a point3
            // comecamos em 1 porque juncao 1->2 esta feita
            int banda_idx;
            int bandas=aircraftZone/visibleWidth;
            if (i >= numberOfAircraft)
                continue;
            [[NSColor blueColor] set];
            for (banda_idx=0; banda_idx<=bandas; banda_idx+=2) {
                NSPoint point_n = NSMakePoint(
                    point1.x + visibleWidth * cos(ang1) * banda_idx,
                    point1.y + visibleWidth * sin(ang1) * banda_idx);
                NSPoint point_n2 = NSMakePoint(
                    point2.x + visibleWidth * cos(ang1) * banda_idx,
                    point2.y + visibleWidth * sin(ang1) * banda_idx);
                    
                NSRect rPt1 = NSMakeRect(point_n.x-visibleWidth/2, point_n.y-visibleWidth/2, visibleWidth, visibleWidth);
                NSRect rPt2 = NSMakeRect(point_n2.x-visibleWidth/2, point_n2.y-visibleWidth/2, visibleWidth, visibleWidth);
                
                [[NSBezierPath bezierPathWithOvalInRect: rPt1] stroke];
                [[NSBezierPath bezierPathWithOvalInRect: rPt2] stroke];
                
                NSPoint point_n3 = NSMakePoint(
                    point2.x + visibleWidth * cos(ang1) * (banda_idx+1),
                    point2.y + visibleWidth * sin(ang1) * (banda_idx+1));
                NSPoint point_n4 = NSMakePoint(
                    point1.x + visibleWidth * cos(ang1) * (banda_idx+1),
                    point1.y + visibleWidth * sin(ang1) * (banda_idx+1));
                
                NSRect rPt3 = NSMakeRect(point_n3.x-visibleWidth/2, point_n3.y-visibleWidth/2, visibleWidth, visibleWidth);
                NSRect rPt4 = NSMakeRect(point_n4.x-visibleWidth/2, point_n4.y-visibleWidth/2, visibleWidth, visibleWidth);
                [[NSBezierPath bezierPathWithOvalInRect: rPt3] stroke];
                [[NSBezierPath bezierPathWithOvalInRect: rPt4] stroke];
                
                // 1 -> 2
                //      |
                // 4 <- 3
                [NSBezierPath strokeLineFromPoint: point_n toPoint: point_n2];
                [NSBezierPath strokeLineFromPoint: point_n2 toPoint: point_n3];
                [NSBezierPath strokeLineFromPoint: point_n3 toPoint: point_n4];
                
                NSMutableDictionary *record1 = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *record2 = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *record3 = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *record4 = [[NSMutableDictionary alloc] init];
                
                [record1 setObject:[[NSNumber numberWithFloat: point_n.x] stringValue] forKey:@"x"];
                [record1 setObject:[[NSNumber numberWithFloat: point_n.y] stringValue] forKey:@"y"];
                [record1 setObject:[sPoint valueForKey:@"alt"] forKey:@"alt"];
                [record1 setObject:[sPoint valueForKey:@"airspeed"] forKey:@"airspeed"];
                [record1 setObject:[[NSNumber numberWithInt: i] stringValue] forKey:@"uavindex"];
                [specificPoints insertObject:record1 atIndex:[specificPoints count]];
                
                [record2 setObject:[[NSNumber numberWithFloat: point_n2.x] stringValue] forKey:@"x"];
                [record2 setObject:[[NSNumber numberWithFloat: point_n2.y] stringValue] forKey:@"y"];
                [record2 setObject:[sPoint valueForKey:@"alt"] forKey:@"alt"];
                [record2 setObject:[sPoint valueForKey:@"airspeed"] forKey:@"airspeed"];
                [record2 setObject:[[NSNumber numberWithInt: i] stringValue] forKey:@"uavindex"];
                [specificPoints insertObject:record2 atIndex:[specificPoints count]];
                
                [record3 setObject:[[NSNumber numberWithFloat: point_n3.x] stringValue] forKey:@"x"];
                [record3 setObject:[[NSNumber numberWithFloat: point_n3.y] stringValue] forKey:@"y"];
                [record3 setObject:[sPoint valueForKey:@"alt"] forKey:@"alt"];
                [record3 setObject:[sPoint valueForKey:@"airspeed"] forKey:@"airspeed"];
                [record3 setObject:[[NSNumber numberWithInt: i] stringValue] forKey:@"uavindex"];
                [specificPoints insertObject:record3 atIndex:[specificPoints count]];
                
                [record4 setObject:[[NSNumber numberWithFloat: point_n4.x] stringValue] forKey:@"x"];
                [record4 setObject:[[NSNumber numberWithFloat: point_n4.y] stringValue] forKey:@"y"];
                [record4 setObject:[sPoint valueForKey:@"alt"] forKey:@"alt"];
                [record4 setObject:[sPoint valueForKey:@"airspeed"] forKey:@"airspeed"];
                [record4 setObject:[[NSNumber numberWithInt: i] stringValue] forKey:@"uavindex"];
                [specificPoints insertObject:record4 atIndex:[specificPoints count]];
                
                NSLog(@"Inserted specific object for uavindex: %d. Count is now: %d", i, [specificPoints count]);
            }

        }
        
    }
	//[self drawCursorPath];
}

- (void)drawCursorPath
{
	// now draw the mouse crosshair
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
	if([defs dataForKey:@"routePlotColor"])
		[[NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routePlotColor"]] set];
	
	[NSBezierPath strokeLineFromPoint:NSMakePoint([self bounds].origin.x,mousePoint.y) toPoint:NSMakePoint([self bounds].size.width,mousePoint.y)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(mousePoint.x,[self bounds].origin.y) toPoint:NSMakePoint(mousePoint.x,[self bounds].size.height)];
}

- (void)drawAircraftPath
{
	float	DEG2RAD = 3.14159/180;
    int i;
	
	// draw circle marking aircraft position
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	
    for (i=0; i<4; i++) {
        NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(aircraftPoint[i].x - (4/zoomLevel), aircraftPoint[i].y - (4/zoomLevel), 8/zoomLevel, 8/zoomLevel)];		
        if( [defs dataForKey:@"routePlotColor"] )
            [[NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routePlotColor"]] set];
        [dot fill];
        [[NSColor blackColor] set];
        [dot stroke];
        
        // draw big oval around aircraft
        NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(aircraftPoint[i].x - (30/zoomLevel), aircraftPoint[i].y - (30/zoomLevel), 60/zoomLevel, 60/zoomLevel)];
        [circle stroke];
        
        // draw heading indicator in route color
        [NSBezierPath setDefaultLineWidth: 2.0];
        if( [defs dataForKey:@"routePlotColor"] )
            [[NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"routePlotColor"]] set];
        [NSBezierPath strokeLineFromPoint: NSMakePoint(aircraftPoint[i].x,aircraftPoint[i].y)
            toPoint: NSMakePoint(aircraftPoint[i].x + cos((aircraftHeading[i]-90)*DEG2RAD) * 30/zoomLevel, aircraftPoint[i].y - sin((aircraftHeading[i]-90)*DEG2RAD) * 30/zoomLevel)];
            
        // draw desired heading indicator in secondary color
        if( [defs dataForKey:@"apIndicatorColor"] )
            [[NSUnarchiver unarchiveObjectWithData:[defs dataForKey:@"apIndicatorColor"]] set];
        [NSBezierPath strokeLineFromPoint: NSMakePoint(aircraftPoint[i].x,aircraftPoint[i].y)
            toPoint: NSMakePoint(aircraftPoint[i].x + cos((desiredHeading[i]-90)*DEG2RAD) * 30/zoomLevel, aircraftPoint[i].y - sin((desiredHeading[i]-90)*DEG2RAD) * 30/zoomLevel)];
            
        [NSBezierPath setDefaultLineWidth: 1.0];
    }
}

- (void)setCursorPoint:(NSPoint)thePoint
{
	/*mousePoint = thePoint;
	[self setNeedsDisplay: YES];
    */
}

- (void)setAircraftPoint:(NSPoint)thePoint heading: (float)newHeading desiredHeading: (float)newDesiredHeading forAddress:(int)uav
{
	/* request redraw of old aircraft point rect and new aircraft point rect (60 pix radius) */
    NSPoint oldPoint = aircraftPoint[uav];
    aircraftPoint[uav] = [self pointCoordinatesFromGps:thePoint];
	aircraftHeading[uav] = newHeading;
	desiredHeading[uav] = newDesiredHeading;
    
    [self setNeedsDisplayInRect: NSMakeRect(oldPoint.x-35, oldPoint.y-35, 70, 70)];
    [self setNeedsDisplayInRect: NSMakeRect(aircraftPoint[uav].x-35, aircraftPoint[uav].y-35, 70, 70)];
    NSLog(@"Drawing UAV %d at %f %f", uav, aircraftPoint[uav].x, aircraftPoint[uav].y);
}

- (float)distanceToLine:(NSPoint)thePoint linePointOne:(NSPoint)linePointOne linePointTwo:(NSPoint)linePointTwo
{
	float mag,u,distance;
	int ix,iy;
	
	//magnitude do vector p2-p1
	mag=[self magnitude: linePointOne point2:linePointTwo];
	u = (((thePoint.x-linePointTwo.x) * (linePointOne.x-linePointTwo.x))
		+
		((thePoint.y-linePointTwo.y) * (linePointOne.y-linePointTwo.y)))
		/
		(mag*mag);
		
	if(u<0 || u>1)
		return -1;
	
	ix = linePointTwo.x + u*(linePointOne.x-linePointTwo.x);
	iy = linePointTwo.y + u*(linePointOne.y-linePointTwo.y);
	
	distance = [self magnitude:thePoint point2:NSMakePoint(ix,iy)];
	return(distance);
}

- (float)distanceInMetersFromLatitude:(float)latitude longitude:(float)longitude toLatitude:(float)destLatitude toLongitude:(float)destLongitude
{
	/* calculate distance between current position and current target waypoint.. */
    /* idiot... convert to rads for trig functions!!!!!! */
    float DEG2RAD = 3.14159/180;
	double t1 = sin(latitude*DEG2RAD)*sin(destLatitude*DEG2RAD);
	double t2 = cos(latitude*DEG2RAD)*cos(destLatitude*DEG2RAD);
	double t3 = cos(longitude*DEG2RAD-destLongitude*DEG2RAD);
	double t4 = t2*t3;
	double t5 = t1+t4;
	double distance = acos( t5 );
	
	/* convert to meters. Earth radius is WGS84 */
	float distance_m = distance * 6366689.6;
        
	return distance_m;
}

- (float)magnitude:(NSPoint)point1 point2:(NSPoint)point2
{
	float mag;
	mag = sqrt( (point1.x-point2.x)*(point1.x-point2.x) + (point1.y-point2.y)*(point1.y-point2.y) );
	return mag;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
                == NSDragOperationGeneric)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they 
            //are offering
        return NSDragOperationGeneric;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have 
            //to tell them we aren't interested
        return NSDragOperationNone;
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationCopy & [sender draggingSourceOperationMask]) 
                    == NSDragOperationCopy)
    {
        //this means that the sender is offering the type of operation we want
        //return that we want the NSDragOperationGeneric operation that they 
            //are offering
        return NSDragOperationCopy;
    }
    else
    {
        //since they aren't offering the type of operation we want, we have 
            //to tell them we aren't interested
        return NSDragOperationNone;
    }
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
        //gets the dragging-specific pasteboard from the sender
    NSArray *types = [NSArray arrayWithObjects:NSTIFFPboardType, 
                    NSFilenamesPboardType, nil];
        //a list of types that we can accept
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];

    if (nil == carriedData)
    {
        //the operation failed for some reason
        NSRunAlertPanel(@"Paste Error", @"Sorry, but the past operation failed", 
            nil, nil, nil);
        return NO;
    }
    else
    {
        //the pasteboard was able to give us some meaningful data
        if ([desiredType isEqualToString:NSTIFFPboardType])
        {
            //we have TIFF bitmap data in the NSData object
            NSImage *newImage = [[NSImage alloc] initWithData:carriedData];
			[backgroundImageData release];
			backgroundImageData = carriedData;
            [self setBackgroundImageData:carriedData];
            [newImage release];    
                //we are no longer interested in this so we need to release it
        }
        else if ([desiredType isEqualToString:NSFilenamesPboardType])
        {
            //we have a list of file names in an NSData object
            NSArray *fileArray = 
                [paste propertyListForType:@"NSFilenamesPboardType"];
                //be caseful since this method returns id.  
                //We just happen to know that it will be an array.
            NSString *path = [fileArray objectAtIndex:0];
                //assume that we can ignore all but the first path in the list
            NSImage *newImage = [[NSImage alloc] initWithContentsOfFile:path];
			
			NSData *newData = [[NSData alloc] initWithContentsOfFile:path];
			[newData retain];
			[backgroundImageData release];
			backgroundImageData = newData;

            if (nil == newImage)
            {
                //we failed for some reason
                NSRunAlertPanel(@"File Reading Error", 
                    [NSString stringWithFormat:
                    @"Sorry, but I failed to open the file at \"%@\"",
                    path], nil, nil, nil);
                return NO;
            }
            else
            {
                //newImage is now a new valid image
                [self setBackgroundImageData:newData];
            }
            [newImage release];
        }
        else
        {
            //this can't happen
            NSAssert(NO, @"This can't happen");
            return NO;
        }
    }
    [self setNeedsDisplay:YES];    //redraw us with the new image
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[self setFrameSize: [backgroundImage size]];
	[self setNeedsDisplay:YES];
}

- (NSPoint)gpsCoordinatesFromPoint:(NSPoint)thePoint
{
	float	startLatitude,endLatitude,latitudeSpan,startLongitude,endLongitude,longitudeSpan,xMultiplier,yMultiplier;
	float	returnX,returnY;
	
	//latitude Ž dist‰ncia ao equador, o nosso eixo y a 2D
	NSNumber *startLatitudeNumber=[baseCoordinates objectForKey:@"startLatitude"];
	startLatitude = [startLatitudeNumber floatValue];
	
	NSNumber *endLatitudeNumber=[baseCoordinates objectForKey:@"endLatitude"];
	endLatitude = [endLatitudeNumber floatValue];
	
	//calcula distancia em graus decimais (default input) entre os pontos inicio e fim.
	//depois Ž 3 simples por equivalencia ˆ distancia entre 0,0 e 640,480
	latitudeSpan = endLatitude-startLatitude;
	
	//longitude Ž dist‰ncia a greenwich, o nosso eixo x a 2D
	NSNumber *startLongitudeNumber=[baseCoordinates objectForKey:@"startLongitude"];
	startLongitude = [startLongitudeNumber floatValue];
	
	NSNumber *endLongitudeNumber=[baseCoordinates objectForKey:@"endLongitude"];
	endLongitude = [endLongitudeNumber floatValue];
	
	//calcula distancia em graus decimais (default input) entre os pontos inicio e fim.
	//depois Ž 3 simples por equivalencia ˆ distancia entre 0,0 e 640,480
	longitudeSpan = endLongitude-startLongitude;
	
	//equivalencia
	yMultiplier = latitudeSpan/[self bounds].size.height;
	returnY = startLatitude + (yMultiplier*thePoint.y);
	
	xMultiplier = longitudeSpan/[self bounds].size.width;
	returnX = startLongitude+(xMultiplier*thePoint.x);
	
	NSPoint outputPoint = NSMakePoint(returnX,returnY);
	
	return outputPoint;
}

- (NSPoint)pointCoordinatesFromGps:(NSPoint)thePoint
{
	float	startLatitude,endLatitude,latitudeSpan,startLongitude,endLongitude,longitudeSpan,latitudeOffset,longitudeOffset;
	float	returnX,returnY;
	
	//latitude Ž dist‰ncia ao equador, o nosso eixo y a 2D
	NSNumber *startLatitudeNumber=[baseCoordinates objectForKey:@"startLatitude"];
	startLatitude = [startLatitudeNumber floatValue];
	
	NSNumber *endLatitudeNumber=[baseCoordinates objectForKey:@"endLatitude"];
	endLatitude = [endLatitudeNumber floatValue];
	
	//calcula distancia em graus decimais (default input) entre os pontos inicio e fim.
	//depois Ž 3 simples por equivalencia ˆ distancia entre 0,0 e 640,480
	latitudeSpan = endLatitude-startLatitude;
	latitudeOffset = endLatitude - thePoint.y;
	//calcular offset como percentagem do span de latitude
	latitudeOffset = latitudeOffset/latitudeSpan;
	returnY = [self bounds].size.height -([self bounds].size.height * latitudeOffset);
	
	//longitude Ž dist‰ncia a greenwich, o nosso eixo x a 2D
	NSNumber *startLongitudeNumber=[baseCoordinates objectForKey:@"startLongitude"];
	startLongitude = [startLongitudeNumber floatValue];
	
	NSNumber *endLongitudeNumber=[baseCoordinates objectForKey:@"endLongitude"];
	endLongitude = [endLongitudeNumber floatValue];
	
	//calcula distancia em graus decimais (default input) entre os pontos inicio e fim.
	//depois Ž 3 simples por equivalencia ˆ distancia entre 0,0 e 640,480
	longitudeSpan = endLongitude-startLongitude;
	longitudeOffset = endLongitude - thePoint.x;
	//calcular odffset como percentagem do span de longitude
	longitudeOffset = longitudeOffset/longitudeSpan;
	returnX = [self bounds].size.width - ([self bounds].size.width * longitudeOffset);
	
	NSPoint outputPoint = NSMakePoint(returnX,returnY);
	
	return outputPoint;
}

-(float)zoomLevel
{
    return zoomLevel;
}

-(void)setNumberOfAircraft:(NSNumber *)theNumber
{
    numberOfAircraft = [theNumber intValue];
}

-(void)setObservationWidth:(NSNumber *)theNumber
{
    observationWidth = [theNumber intValue];
}

-(void)setObservationStartPoint:(NSNumber *)theNumber
{
    observationStartPoint = [theNumber intValue];
}

-(void)setCameraAperture:(NSNumber *)theNumber
{
    cameraAperture = [theNumber intValue];
}

@end