//
//  FrontRowTunesAppDelegate.m
//  FrontRowTunes
//
//  Created by Alexander Decker on 14.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FrontRowTunesAppDelegate.h"

@implementation FrontRowTunesAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// prevent the display from sleeping
	/*IOReturn success = */
	IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, (CFStringRef)@"FrontRowTunes", &assertionID); // display sleep prevention
}


- (void)applicationWillTerminate:(NSNotification *)notification {
	// this will get called if the application is quit, but not if it is killed or crashes!
	/*IOReturn success = */
	IOPMAssertionRelease(assertionID); // display sleep prevention
	
}


@end
