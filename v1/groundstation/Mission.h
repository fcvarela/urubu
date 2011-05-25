//
//  Mission.h
//  testbed2
//
//  Created by Filipe Varela on 05/06/16.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Mission : NSObject {
	NSMutableArray *waypointsArray;
	NSMutableDictionary *baseCoordinates;
	NSImage *backgroundImage;
	NSData *backgroundImageData;
    NSNumber *observationStartPoint;
    NSNumber *numberOfAircraft;
    NSNumber *observationWidth;
    NSNumber *cameraAperture;
}

- (NSMutableArray *)returnWaypoints;
- (NSMutableDictionary *)returnBaseCoordinates;
- (NSData *)returnBackgroundImageData;
- (NSNumber *)returnObservationStartPoint;
- (NSNumber *)returnNumberOfAircraft;
- (NSNumber *)returnObservationWidth;
- (NSNumber *)returnCameraAperture;

- (void)setBaseCoordinates:(NSMutableDictionary *)theCoords;
- (void)setObservationStartPoint:(NSNumber *)theIndex;
- (void)setBackgroundImageData:(NSData *)bgImgData;
- (void)setNumberOfAircraft:(NSNumber *)theNumber;
- (void)setObservationWidth:(NSNumber *)theNumber;
- (void)setCameraAperture:(NSNumber *)theNumber;

- (void)saveWaypointsAs:(NSString *)filePath;
- (void)loadWaypointsFromFile:(NSString *)filePath;


@end
