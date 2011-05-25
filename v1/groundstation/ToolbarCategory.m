//
//  ToolbarCategory.m
//  testbed2
//
//  Created by Filipe Varela on 05/06/16.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ToolbarCategory.h"


@implementation MissionWindowController (ToolbarCategory)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    if ( [itemIdentifier isEqualToString:@"LoadMission"] ) {
        [item setLabel:@"Load Mission"];
        [item setPaletteLabel:[item label]];
        //[item setImage:[NSImage imageNamed:@"Add"]];
        [item setTarget:self];
        [item setAction:@selector(loadMission:)];
    } else if ( [itemIdentifier isEqualToString:@"SaveMission"] ) {
        [item setLabel:@"Save mission"];
        [item setPaletteLabel:[item label]];
        //[item setImage:[NSImage imageNamed:@"Remove"]];
        [item setTarget:self];
        [item setAction:@selector(saveMission:)];
    } else if ( [itemIdentifier isEqualToString:@"ResetMission"] ) {
		[item setLabel:@"Reset Mission"];
		[item setPaletteLabel:[item label]];
		[item setTarget: self];
		[item setAction:@selector(resetMission:)];
    } else if ( [itemIdentifier isEqualToString:@"Properties"] ) {
		[item setLabel:@"Properties"];
		[item setPaletteLabel:[item label]];
		[item setTarget: self];
		[item setAction:@selector(showPropertiesPanel:)];
    } else if ( [itemIdentifier isEqualToString:@"UploadMission"] ) {
        [item setLabel:@"Upload Mission"];
		[item setPaletteLabel:[item label]];
		[item setTarget: self];
		[item setAction:@selector(uploadMission:)];
    }

    return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:/*NSToolbarSeparatorItemIdentifier,
                                     NSToolbarSpaceItemIdentifier,
                                     NSToolbarFlexibleSpaceItemIdentifier,
                                     NSToolbarCustomizeToolbarItemIdentifier, */
									 @"LoadMission",
									 @"SaveMission",
									 @"ResetMission",
									 @"Properties",
                                     @"UploadMission",
									 nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"LoadMission",
									 @"SaveMission",
									 @"ResetMission",
									 @"Properties",
                                     @"UploadMission",
									 nil];
}

- (void)setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	[[self window] setToolbar:[toolbar autorelease]];
}
@end
