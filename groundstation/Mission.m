//
//  Mission.m
//  testbed2
//
//  Created by Filipe Varela on 05/06/16.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "Mission.h"

@implementation Mission

-(id)init
{
	waypointsArray = [[NSMutableArray alloc] init];
	return self;
}

- (NSMutableArray *)returnWaypoints
{
	return waypointsArray;
}

- (NSMutableDictionary *)returnBaseCoordinates
{
	return baseCoordinates;
}

- (void)setBaseCoordinates:(NSMutableDictionary *)theCoords
{
	baseCoordinates = theCoords;
}

- (void)setBackgroundImageData:(NSData *)bgImgData
{
	[bgImgData retain];
	[backgroundImageData release];
	backgroundImageData = [[NSData alloc] initWithData:bgImgData];
}

- (void)saveWaypointsAs:(NSString *)filePath
{
	NSMutableDictionary *mission = [[NSMutableDictionary alloc] init];
	
	if(waypointsArray)
		[mission setObject:waypointsArray forKey:@"waypoints"];
	if(baseCoordinates)
		[mission setObject:baseCoordinates forKey:@"baseCoordinates"];
	if(backgroundImageData)
		[mission setObject:backgroundImageData forKey:@"backgroundImage"];
    if(observationStartPoint)
        [mission setObject: observationStartPoint forKey:@"observationStartPoint"];
    if(observationWidth)
        [mission setObject: observationWidth forKey:@"observationWidth"];
    if(numberOfAircraft)
        [mission setObject: numberOfAircraft forKey:@"numberOfAircraft"];
    if(cameraAperture)
        [mission setObject: cameraAperture forKey:@"cameraAperture"];
	
	//use encoder in mission dictionary.
	if (![mission writeToFile:filePath atomically:YES])
		NSBeep();
}

- (void)loadWaypointsFromFile:(NSString *)filePath
{
   NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile: filePath];
   waypointsArray=[preferences objectForKey:@"waypoints"];
   backgroundImageData=[[NSData alloc] initWithData: [preferences objectForKey:@"backgroundImage"]];
   backgroundImage = [[NSImage alloc] initWithData: backgroundImageData];
   baseCoordinates=[preferences objectForKey:@"baseCoordinates"];
   observationStartPoint=[preferences objectForKey:@"observationStartPoint"];
   observationWidth=[preferences objectForKey:@"observationWidth"];
   numberOfAircraft=[preferences objectForKey:@"numberOfAircraft"];
   cameraAperture=[preferences objectForKey:@"cameraAperture"];
}

- (NSData *)returnBackgroundImageData
{
	return backgroundImageData;
}

- (void)setObservationWidth:(NSNumber *)theNumber
{
    observationWidth = theNumber;
}

- (NSNumber *)returnObservationWidth
{
    return observationWidth;
}

- (void)setObservationStartPoint:(NSNumber *)thePoint
{
    observationStartPoint = thePoint;
}

- (NSNumber *)returnObservationStartPoint
{
    return observationStartPoint;
}

- (void)setNumberOfAircraft:(NSNumber *)theNumber
{
    numberOfAircraft = theNumber;
}

- (void)setCameraAperture:(NSNumber *)theNumber
{
    cameraAperture = theNumber;
}

- (NSNumber *)returnNumberOfAircraft
{
    return numberOfAircraft;
}

- (NSNumber *)returnCameraAperture
{
    return cameraAperture;
}

@end
