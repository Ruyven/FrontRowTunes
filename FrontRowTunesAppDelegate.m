//
//  FrontRowTunesAppDelegate.m
//  FrontRowTunes
//
//  Created by Alexander Decker on 14.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FrontRowTunesAppDelegate.h"
#import <IOKit/pwr_mgt/IOPMLib.h>

@implementation FrontRowTunesAppDelegate

@synthesize window;

IOPMAssertionID assertionID;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// prevent the display from sleeping
	/*IOReturn success = */
	IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, (CFStringRef)@"FrontRowTunes", &assertionID);
	
	// create a RemoteController instance
	remoteController = [[RemoteController alloc] init];
	[remoteController setSongView:songView];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	// this will get called if the application is quit, but not if it is killed or crashes!
	/*IOReturn success = */
	IOPMAssertionRelease(assertionID);
	
}


@end
