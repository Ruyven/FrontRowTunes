//
//  SongView.m
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SongView.h"


@implementation SongView

@synthesize whiteBackground;
@synthesize prevTrack;

- (void)awakeFromNib {
	firstSong = YES;
	switchTrack = NO;
	justChangedTrack = NO;
	allowScreenChange = YES;
	
	// ToDo: einstellbar machen
	displayPlayerPositionBar = YES;
	displayPlayerPositionLabel = NO;
	displayClock = NO;
	clockSeconds = NO;
	
	// go full screen
	/*DEBUG: Don't go full screen.
    NSMutableDictionary *fullScreenOptions = [[NSMutableDictionary alloc] init];
	[fullScreenOptions setObject:[NSNumber numberWithBool:NO] forKey:NSFullScreenModeAllScreens];
	
	[self enterFullScreenMode:[NSScreen mainScreen] withOptions:fullScreenOptions];
	
	[self.window setStyleMask:NSBorderlessWindowMask];
	//DEBUG [self.window setLevel:CGShieldingWindowLevel()];

	[self.window setFrame:[[NSScreen mainScreen] frame] display:NO];
	//[self.window setFrame:[[[NSScreen screens] objectAtIndex:1] frame] display:NO];//DEBUG*/

	// Make the window the first responder to get keystrokes
	[self.window makeFirstResponder:self];

	// initialize iTunes
	iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	currentSongID = @"";
	playerPosition = (double)[iTunes playerPosition];
	
	[self setupLayers];
	[self getTrack:nil];

	// bring the window to the front
	[self.window makeKeyAndOrderFront:self];
    
    // ToDo DontForge: if the app is fullscreen, find a way to switch to it automatically!
	
    // mouse-tracking
    trackingArea = [[NSTrackingArea alloc] initWithRect:self.frame options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp) owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
    
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(getTrack:) name:@"com.apple.iTunes.playerInfo" object:nil];

	updatePlayerPositionTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATEINTERVAL target:self selector:@selector(updatePlayerPosition) userInfo:nil repeats:YES];
}

- (void)setupLayers {
	CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
	CGColorRef whiteColor = CGColorCreateGenericRGB(1, 1, 1, 1);
	
	rootLayer = [CALayer layer];
	[rootLayer setBackgroundColor:blackColor];
	[self setLayer:rootLayer];
	[self setWantsLayer:YES];
	
	activeSongLayer = [[SongLayer alloc] initWithFrame:[self frame] whiteBackground:whiteBackground];
	activeSongLayer.playerPosition = playerPosition;
	[activeSongLayer setPlayerState:[iTunes playerState]];
	activeSongLayer.displayPlayerPositionBar = displayPlayerPositionBar;
	activeSongLayer.displayPlayerPositionLabel = displayPlayerPositionLabel;
	activeSongLayer.displayClock = displayClock;
	activeSongLayer.clockSeconds = clockSeconds;
	
	
	//	[activeSongLayer setBackgroundColor:CGColorCreateGenericRGB(0, 0, 1, 1)];
	// auto-resize activeSongLayer as the view is resized
	[activeSongLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
	[rootLayer addSublayer:activeSongLayer];
	[activeSongLayer layoutIfNeeded];
	
	remoteEventLayer = [CALayer layer];
	remoteEventLayer.frame = [self frame];
	[activeSongLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
	remoteEventLayer.backgroundColor = whiteColor;
	remoteEventLayer.opacity = 0;
	remoteEventLayer.zPosition = 2;
	[rootLayer addSublayer:remoteEventLayer];
	
	// cleanup
	CGColorRelease(blackColor);
	CGColorRelease(whiteColor);
}

- (void)getTrack:(NSNotification *)notification {
    iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"]; // am I going to have to do that every time?
	NSString *songID = [[iTunes currentTrack] persistentID];
	if (![songID isEqualToString:currentSongID]) {
		// Lied wurde gewechselt!
		if (prevTrack) {
			// wenn das prevTrackEvent nicht länger als drei Sekunden her ist, wurde der Track gerade zurück gewechselt!
			if (-[prevTrackTimeStamp timeIntervalSinceNow] >= 3) {
				prevTrack = NO;
			}
		}
		
		[self setTrack:[iTunes currentTrack] prev:prevTrack];
		prevTrack = NO;
		currentSongID = [songID retain];
	}
	[activeSongLayer setPlayerState:[iTunes playerState]];
}

- (void)setTrack:(iTunesTrack *)track prev:(BOOL)prev {
    iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"]; // am I going to have to do that every time?
	if (firstSong || justChangedTrack) {
		[activeSongLayer setTrack:[iTunes currentTrack]];
		firstSong = NO;
	} else {
		// generate new SongLayer
		
		activeSongLayer.zPosition = 1;
		
		[CATransaction begin];
		[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
		[CATransaction setAnimationDuration:0.5f];
		if (!prev) {
			// normale Animation: Layer vergrößern
			[activeSongLayer setAffineTransform:CGAffineTransformMake(5, 0, 0, 5, 0, 0)];
		} else {
			[activeSongLayer setAffineTransform:CGAffineTransformMake(.2, 0, 0, .2, 0, 0)];
		}
		
		// inner transaction
		[CATransaction begin];
//		[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
		[CATransaction setAnimationDuration:0.5f];
		activeSongLayer.opacity = 0;
		[CATransaction commit];

		[CATransaction commit];

		lastSongLayer = activeSongLayer;
		
		//	[songLayer removeFromSuperlayer];
		
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		
		activeSongLayer = [[SongLayer alloc] initWithFrame:[self frame] whiteBackground:whiteBackground];
		//	[activeSongLayer setBackgroundColor:CGColorCreateGenericRGB(0, 0, 1, 1)];
		// auto-resize activeSongLayer as the view is resized
		[activeSongLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
		[activeSongLayer setTrack:[iTunes currentTrack]];
		// position is zero, so that doesn't have to be set
		[activeSongLayer setPlayerState:[iTunes playerState]];
		if (!prev) {
			// normale Animation: Layer fängt klein an
			[activeSongLayer setAffineTransform:CGAffineTransformMakeScale(.2, .2)];
		} else {
			[activeSongLayer setAffineTransform:CGAffineTransformMakeScale(5, 5)];
		}
		activeSongLayer.opacity = 0.0;
		activeSongLayer.displayPlayerPositionBar = displayPlayerPositionBar;
		activeSongLayer.displayPlayerPositionLabel = displayPlayerPositionLabel;
		activeSongLayer.displayClock = displayClock;
		activeSongLayer.clockSeconds = clockSeconds;
		
		[rootLayer addSublayer:activeSongLayer];
		[CATransaction commit];
//		[nextSongLayer layoutIfNeeded];
		
		[NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(activateNewLayer) userInfo:nil repeats:NO];
		allowScreenChange = NO;
		
		justChangedTrack = YES;
		/*if (changeTrackTimer != nil) {
//			if ([changeTrackTimer isValid]) {
				NSLog(@"invalidate");
				[changeTrackTimer invalidate];
			// ToDo: funktioniert irgendwie nicht, er wird trotzdem nach einer Sekunde vom ersten Setzen an gefeuert, aber ist jetzt auch egal
//			}
			NSLog(@"release");
			[changeTrackTimer release];
		}*/
		changeTrackTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(resetJustChangedTrack) userInfo:nil repeats:NO] retain];
	}
}

- (void)activateNewLayer {
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	[CATransaction setValue:[NSNumber numberWithFloat:0.5f] forKey:kCATransactionAnimationDuration];
	activeSongLayer.opacity = 1;
	[activeSongLayer setAffineTransform:CGAffineTransformMake(1, 0, 0, 1, 0, 0)];
	
	allowScreenChange = YES;
}

- (void)resetJustChangedTrack {
	justChangedTrack = NO;
	
	// also cleanup the last song layer
	if (lastSongLayer != nil) {
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		[lastSongLayer removeFromSuperlayer];
		[CATransaction commit];
		[lastSongLayer release];
		lastSongLayer = nil;
	}
}

- (void)keyDown:(NSEvent *)event {
    iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"]; // am I going to have to do that every time?

	NSString *character = [event characters];
	int characterInt = [character intValue];
	keyCode = [event keyCode];
	
	if (characterInt >= 1 && characterInt <= 9) {
		int screen = characterInt - 1;
		NSArray *screenArray = [NSScreen screens];
		if (allowScreenChange && screen < [screenArray count]) {
			// screen change is not allowed when the song is changed, otherwise the new songLayer would be too small
			
			// if animate is YES, you can see the window resize over to the other display
			[self.window setFrame:[[screenArray objectAtIndex:screen] frame] display:YES animate:NO];
		}
	} else if ([character isEqualToString:@" "]) {
		[iTunes playpause];
	} else if ([character isEqualToString:@"t"]) {
		if (clockSeconds) {
			clockSeconds = NO;
			if (!displayClock) displayClock = YES;
			activeSongLayer.clockSeconds = clockSeconds;
		} else {
			displayClock = !displayClock;
		}
		activeSongLayer.displayClock = displayClock;
		[activeSongLayer updateClock];
		[activeSongLayer updateWithDuration:.5];
	} else if ([character isEqualToString:@"T"]) {
		if (!clockSeconds) {
			clockSeconds = YES;
			if (!displayClock) displayClock = YES;
			activeSongLayer.clockSeconds = clockSeconds;
		} else {
			displayClock = !displayClock;
		}
		activeSongLayer.displayClock = displayClock;
		[activeSongLayer updateClock];
		[activeSongLayer updateWithDuration:.5];
/*	} else if (keyCode == 123 || keyCode == 124) {
		switchTrack = YES;*/
		// ToDo: bei langem drücken spulen, ansonsten nextTrack bzw. backTrack
		// oder einfach wie iTunes: beim keyDown nextTrack bzw. backTrack
//		[NSTimer 
		// 123 = previous, 124 = next
//		[iTunes backTrack];
	} else if (keyCode == 123) {
		// links
		self.prevTrack = YES;
		[iTunes backTrack];
	} else if (keyCode == 124) {
		// rechts
		self.prevTrack = NO;
		[iTunes nextTrack];
	} else if (keyCode == 53 || [character isEqualToString:@"q"] || [character isEqualToString:@"Q"]) {
		// Esc oder Q
		[NSApp terminate:self];
/*	} else if ([character isEqualToString:@"h"]) {
		[NSApp hide:self]; // doesn't seem to work.*/
	} else if (keyCode == 36) {			// Return
		displayPlayerPositionLabel = !displayPlayerPositionLabel;
		[activeSongLayer setDisplayPlayerPositionLabel:displayPlayerPositionLabel];
		[activeSongLayer updateWithDuration:.5];
	} else if (keyCode == 76) {			// fn+Return or Enter
		displayPlayerPositionBar = !displayPlayerPositionBar;
		[activeSongLayer setDisplayPlayerPositionBar:displayPlayerPositionBar];
		[activeSongLayer updateWithDuration:.5];
	} else if ([character isEqualToString:@"w"]) {
		[CATransaction setValue:[NSNumber numberWithFloat:0.5f] forKey:kCATransactionAnimationDuration];
		whiteBackground = YES;
		[activeSongLayer setWhiteBackground:YES];
		CGColorRef whiteColor = CGColorCreateGenericRGB(1, 1, 1, 1);
		[rootLayer setBackgroundColor:whiteColor];
		CGColorRelease(whiteColor);
		[activeSongLayer updateWithDuration:0.5];
	} else if ([character isEqualToString:@"b"]) {
		[CATransaction setValue:[NSNumber numberWithFloat:0.5f] forKey:kCATransactionAnimationDuration];
		whiteBackground = NO;
		[activeSongLayer setWhiteBackground:NO];
		CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
		[rootLayer setBackgroundColor:blackColor];
		CGColorRelease(blackColor);
		[activeSongLayer updateWithDuration:0.5];
	} else {
		NSLog(@"keyCode:%d character:%@",[event keyCode],character);
	}
}

- (void)updatePlayerPosition {
    iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"]; // am I going to have to do that every time?
	int newPlayerPosition = [iTunes playerPosition];
	
	if (newPlayerPosition != playerPosition) {
		if (newPlayerPosition == 0) {
			NSString *songID = [[iTunes currentTrack] persistentID];
			if ([songID isEqualToString:currentSongID]) {
				// current song started over
				self.prevTrack = NO;
			} else {
				return; // if song just changed, don't update until the notification reaches FrontRowTunes
			}
		} else if (!displayPlayerPositionBar && abs(newPlayerPosition - playerPosition) > 1) {
			// weit gespult, zeig die PlayerPosition irgendwie an (bar anzeigen, wenn label ausgeblendet)
			activeSongLayer.displayPlayerPositionBar = !displayPlayerPositionLabel;
			[activeSongLayer updateWithDuration:.1];
		} else if (activeSongLayer.displayPlayerPositionBar != displayPlayerPositionBar) {
			activeSongLayer.displayPlayerPositionBar = displayPlayerPositionBar;
			[activeSongLayer updateWithDuration:2.0];
		}
			
		playerPosition = newPlayerPosition;
		activeSongLayer.playerPosition = playerPosition;
	}
	
	// update the clock as well
	[activeSongLayer updateClock];
	
	// mein Versuch, eine flüssige Positionsanzeige hinzubekommen
	// die ganze Funktion ist etwas fragwürdig; optimal wär, trotz allem als int zu speichern und per Timestamp zu kontrollieren, wie lang das her ist, und das dann dazuzählen, wenn Pause gemacht wird
/*	if (![activeSongLayer paused]) {
		if (newPlayerPosition == (int)playerPosition) {
			// playerPosition ist nach UPDATEINTERVAL Sekunden immer noch gleich
			playerPosition = newPlayerPosition + UPDATEINTERVAL; // funktioniert in der Form nur mit UPDATEINTERVAL == 0.5
		}
		else {
			playerPosition = newPlayerPosition;
		}
		activeSongLayer.playerPosition = playerPosition;
	} else if (newPlayerPosition != (int)playerPosition) {
		playerPosition = newPlayerPosition;
		activeSongLayer.playerPosition = playerPosition;
	}*/
}

- (void)setPrevTrack:(BOOL)newPrevTrack {
	prevTrack = newPrevTrack;
	if (prevTrack) {
		prevTrackTimeStamp = [[NSDate date] retain];
	}
}

- (void)showRemoteEvent {
	[CATransaction begin];
	[CATransaction setAnimationDuration:0.0];
	remoteEventLayer.opacity = whiteBackground ? .3 : 0.15;
	[CATransaction commit];

	[CATransaction begin];
	[CATransaction setAnimationDuration:1.0];
	remoteEventLayer.opacity = 0.0;
	[CATransaction commit];
}

#pragma mark - Mouse Tracking

- (void)setFrame:(NSRect)frameRect {
    NSLog(@"setting frame");
    [super setFrame:frameRect];
    [self removeTrackingArea:trackingArea];
    trackingArea = [[NSTrackingArea alloc] initWithRect:frameRect options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp) owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [NSCursor hide];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [NSCursor unhide];
}

@end
