//
//  SongView.h
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "iTunes.h"
#import "SongLayer.h"



@interface SongView : NSView <NSWindowDelegate> {
    iTunesApplication *iTunes;
	NSString *currentSongID;
	
	CALayer *rootLayer;
	CALayer *remoteEventLayer;
	SongLayer *activeSongLayer;
	SongLayer *lastSongLayer;
	BOOL justChangedTrack;
	BOOL allowScreenChange;
	NSTimer *changeTrackTimer;
	
	BOOL firstSong;
	BOOL switchTrack;
	BOOL prevTrack;
	NSDate *prevTrackTimeStamp;
	
	int keyCode;
	BOOL whiteBackground;
	
	double playerPosition;
	NSTimer *updatePlayerPositionTimer;
	
	BOOL displayPlayerPositionBar, displayPlayerPositionLabel, displayClock, clockSeconds;
    
    NSTrackingArea *trackingArea;
}

- (void)setupLayers;
- (void)activateNewLayer;

- (void)getTrack:(NSNotification *)notification;
- (void)setTrack:(iTunesTrack *)track prev:(BOOL)prev;

- (void)resetJustChangedTrack;

- (void)updatePlayerPosition;

- (void) showRemoteEvent;

@property BOOL whiteBackground;
@property (nonatomic) BOOL prevTrack;

@end
