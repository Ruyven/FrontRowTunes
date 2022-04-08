//
//  SongView.h
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>
#import "FrontRowTunes-Swift.h"
#import "SongLayer.h"

@interface SongView : NSView <NSWindowDelegate, LastEventTrackerDelegate> {
	NSString *currentSongID;
	
	CALayer *rootLayer;
	CALayer *remoteEventLayer;
    CALayer *infoLayer;
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
    BOOL infoLayerOn;
	
	double playerPosition;
	NSTimer *updatePlayerPositionTimer;
	
	BOOL displayPlayerPositionBar, displayPlayerPositionLabel, displayClock, clockSeconds;
    
    NSTrackingArea *trackingArea;
    
    LastEventTracker *lastEventTracker;
}

- (void)setupLayers;
- (void)activateNewLayer;

- (void)getTrack:(NSNotification *)notification;
- (void)setTrack:(MusicTrack *)track prev:(BOOL)prev;

- (void)resetJustChangedTrack;

- (void)updatePlayerPosition;

- (void)showRemoteEvent;

@property BOOL whiteBackground;
@property (nonatomic) BOOL prevTrack;

@property (weak, nonatomic) IBOutlet NSPanel *infoPanel;

- (IBAction)toggleInfoPanel:(id)sender;

@end
