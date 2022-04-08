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
	
	// ToDo: einstellbar machen, bzw. letzte Einstellung speichern
	displayPlayerPositionBar = YES;
	displayPlayerPositionLabel = NO;
	displayClock = NO;
	clockSeconds = NO;
	

	// make this view the first responder to get keystrokes
	[self.window makeFirstResponder:self];
    [self.window setDelegate:self];

	// initialize iTunes //TODO: update comments and method names to Music
	currentSongID = @"";
	playerPosition = [MusicBridge getPlayerPosition];
	
	[self setupLayers];
    [self setTrack:[MusicBridge getCurrentTrack] prev:nil];
	
	// bring the window to the front
	[self.window makeKeyAndOrderFront:self];
    
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(getTrack:) name:@"com.apple.Music.playerInfo" object:nil];

	updatePlayerPositionTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATEINTERVAL target:self selector:@selector(updatePlayerPosition) userInfo:nil repeats:YES];
    
    lastEventTracker = [[LastEventTracker alloc] init];
    [lastEventTracker setDelegate:self timeout:60];
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
	[activeSongLayer setPlayerState:[MusicBridge getPlayerState]];
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
    MusicTrack *track = [MusicBridge getCurrentTrack];
    if (![track.id isEqualToString:currentSongID]) {
        // Lied wurde gewechselt!
        if (prevTrack) {
            // wenn das prevTrackEvent nicht länger als drei Sekunden her ist, wurde der Track gerade zurück gewechselt!
            if (-[prevTrackTimeStamp timeIntervalSinceNow] >= 3) {
                prevTrack = NO;
            }
        }
        
        [self setTrack:[MusicBridge getCurrentTrack] prev:prevTrack];
        prevTrack = NO;
    }
    
	[activeSongLayer setPlayerState:[MusicBridge getPlayerState]];
}

- (void)setTrack:(MusicTrack *)track prev:(BOOL)prev {
    currentSongID = track.id;
    if (firstSong || justChangedTrack) {
        [activeSongLayer setTrack:track];
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
		[activeSongLayer setTrack:track];
		// position is zero, so that doesn't have to be set
		[activeSongLayer setPlayerState:[MusicBridge getPlayerState]];
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
		changeTrackTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(resetJustChangedTrack) userInfo:nil repeats:NO];
	}
}

- (void)activateNewLayer {
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	[CATransaction setValue:@0.5f forKey:kCATransactionAnimationDuration];
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
		lastSongLayer = nil;
	}
}

- (void)keyDown:(NSEvent *)event {
    NSString *character = [event characters];
	int characterInt = [character intValue];
	keyCode = [event keyCode];
	
	if (characterInt >= 1 && characterInt <= 9) {
		int screen = characterInt - 1;
		NSArray *screenArray = [NSScreen screens];
		if (allowScreenChange && screen < [screenArray count]) {
			// screen change is not allowed when the song is changed, otherwise the new songLayer would be too small
			
			// if animate is YES, you can see the window resize over to the other display
			[self.window setFrame:[screenArray[screen] frame] display:YES animate:YES];
		}
	} else if ([character isEqualToString:@" "]) {
        [MusicBridge playpause];
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
		// oder einfach wie iTunes lassen: beim keyDown nextTrack bzw. backTrack
//		[NSTimer 
		// 123 = previous, 124 = next
//		[iTunes backTrack];
	} else if (keyCode == 123) {
		// links
		self.prevTrack = YES;
		[MusicBridge backTrack];
	} else if (keyCode == 124) {
		// rechts
		self.prevTrack = NO;
		[MusicBridge nextTrack];
	} else if ([character isEqualToString:@"q"] || [character isEqualToString:@"Q"]) {
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
		[CATransaction setValue:@0.5f forKey:kCATransactionAnimationDuration];
		whiteBackground = YES;
		[activeSongLayer setWhiteBackground:YES];
		CGColorRef whiteColor = CGColorCreateGenericRGB(1, 1, 1, 1);
		[rootLayer setBackgroundColor:whiteColor];
		CGColorRelease(whiteColor);
		[activeSongLayer updateWithDuration:0.5];
	} else if ([character isEqualToString:@"b"]) {
		[CATransaction setValue:@0.5f forKey:kCATransactionAnimationDuration];
		whiteBackground = NO;
		[activeSongLayer setWhiteBackground:NO];
		CGColorRef blackColor = CGColorCreateGenericRGB(0, 0, 0, 1);
		[rootLayer setBackgroundColor:blackColor];
		CGColorRelease(blackColor);
		[activeSongLayer updateWithDuration:0.5];
    } else if ([character isEqualToString:@"f"] || (keyCode == 53 && [self isWindowFullScreen])) {
        // esc quits out of fullscreen
        [self.window toggleFullScreen:self];
    } else if ([character isEqualToString:@"i"] || [character isEqualToString:@"h"]) {
        [self toggleInfoPanel:nil];
	}
    /*else {
		NSLog(@"keyCode:%d character:%@",[event keyCode],character);
	}*/
}

- (void)updatePlayerPosition {
    int newPlayerPosition = (int)[MusicBridge getPlayerPosition];
	
	if (newPlayerPosition != playerPosition) {
		if (newPlayerPosition == 0) {
			NSString *songID = [MusicBridge getTrackID];
			if ([songID isEqualToString:currentSongID]) {
				// current song started over
				self.prevTrack = NO;
			} else {
				return; // if song just changed, don't update until the notification reaches FrontRowTunes
			}
        } else if (!displayPlayerPositionBar && fabs(newPlayerPosition - playerPosition) > 1) {
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
		prevTrackTimeStamp = [NSDate date];
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

- (IBAction)toggleInfoPanel:(id)sender {
    infoLayerOn = _infoPanel.isVisible;
    if (infoLayerOn) {
        [_infoPanel close];
    } else {
        [_infoPanel orderFront:nil];
        [_infoPanel setLevel:1];
    }
}

#pragma mark Window Delegate

- (void)mouseEntered:(NSEvent *)theEvent {
    [NSCursor hide];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [NSCursor unhide];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    [NSCursor hide];
    trackingArea = [[NSTrackingArea alloc] initWithRect:self.frame options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp) owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    [NSCursor unhide];
    [self removeTrackingArea:trackingArea];
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    remoteEventLayer.frame = frameRect;
}

- (void)windowWillClose:(NSNotification *)notification {
	[NSApp terminate:self];
}

#pragma mark

- (bool)isWindowFullScreen {
    return ([self.window styleMask] & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen;
}

- (void)lastEventTracker:(LastEventTracker *)lastEventTracker timeoutPassed:(NSTimeInterval)timeoutPassed {
    if ([MusicBridge getPlayerState] == MusicBridge.PLAYER_STATE_PLAYING) {
        if ([self isWindowFullScreen]) {
            if (![NSApp isActive]) {
                [NSApp activateIgnoringOtherApps:true];
                [self.window makeKeyAndOrderFront:self];
            }
        } else {
            [self.window toggleFullScreen:self];
        }
    }
}

@end
