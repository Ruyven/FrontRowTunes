//
//  RemoteController.m
//  FrontRowTunes
//
//  Created by Alexander Decker on 17.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RemoteController.h"
#import "SongView.h"

@implementation RemoteController

- (id)init {
	if (self = [super init]) {
		if ((hidRemote = [[HIDRemote alloc] init]) != nil) {
			[hidRemote setDelegate:self];
			// register for remote control events
			[hidRemote startRemoteControl:kHIDRemoteModeShared];
		}
	}
	return self;
}

- (void)dealloc {
	// release hidRemote
	if ([hidRemote isStarted])
	{
		[hidRemote stopRemoteControl];
	}
	[hidRemote setDelegate:nil];
	hidRemote = nil;

}

- (void)hidRemote:(HIDRemote *)hidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(NSMutableDictionary *)attributes {
	if (buttonCode == kHIDRemoteButtonCodeMenuHold) {
		// when the user holds the menu button, quit (terminate) the app.
		[NSApp terminate:self];
	} else if (buttonCode == kHIDRemoteButtonCodeLeft && !isPressed) {
		// released left button
		// notify songView that the track might be changed to the previous track
		if (songView != nil) {
			songView.prevTrack = YES;
		}
	} else if (buttonCode == kHIDRemoteButtonCodeRight && !isPressed) {
		// released right button
		// notify songView that the track might be changed to the previous track
		if (songView != nil) {
			songView.prevTrack = NO;
		}
	} else if (buttonCode == kHIDRemoteButtonCodeUp || buttonCode == kHIDRemoteButtonCodeDown) {
		[songView showRemoteEvent];
	}
}

- (void)setSongView:(SongView *)aSongView {
	songView = aSongView;
}

@end
