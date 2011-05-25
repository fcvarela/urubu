//
//  ToolbarCategory.m
//  testbed2
//
//  Created by Filipe Varela on 05/06/16.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "preferencesWindowToolbar.h"


@implementation PreferencesWindowController (ToolbarCategory)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    if ( [itemIdentifier isEqualToString:@"Mission"] ) {
        [item setLabel:@"Mission"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"prefsToolbarMission"]];
        [item setTarget:self];
        [item setAction:@selector(showMapPrefsView:)];
    } else if ( [itemIdentifier isEqualToString:@"Video"] ) {
        [item setLabel:@"Video"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"banner-video"]];
        [item setTarget:self];
        [item setAction:@selector(showVideoPrefsView:)];
    } else if ( [itemIdentifier isEqualToString:@"Joystick"] ) {
        [item setLabel:@"Joystick"];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"banner-joystick"]];
        [item setTarget:self];
        [item setAction:@selector(showJoystickPrefsView:)];
    }

    return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
                                     NSToolbarSpaceItemIdentifier,
                                     NSToolbarFlexibleSpaceItemIdentifier,
                                     NSToolbarCustomizeToolbarItemIdentifier,
									 @"Mission",
									 @"Video",
									 @"Joystick",
									 nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"Mission",
									 @"Video",
									 @"Joystick",
									 nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:@"Mission",@"Video",@"Joystick",nil];
}

- (void)setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar2"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
	[[self window] setToolbar:[toolbar autorelease]];
}
	
@end
