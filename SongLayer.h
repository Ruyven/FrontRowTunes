//
//  SongLayer.h
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "iTunes.h"
#import "CoverLayer.h"

#define UPDATEINTERVAL 0.5


@interface SongLayer : CALayer {
	CATextLayer *songInfoTextLayer;
	CoverLayer *coverLayer;
	CALayer *trackDurationLayer;
	CALayer *playerPositionLayer;
	CALayer *pauseLayer;
	CATextLayer *timePassedLayer;
	CATextLayer *timeRemainingLayer;
	CATextLayer *clockLayer;
	
	CGFloat durationLayerHeight;
	CGFloat durationLayerYPosition;
	
	iTunesTrack *track;
	BOOL coverExists;

	BOOL whiteBackground;
	NSColor *backgroundColor;
	NSColor *foregroundColor;
	NSColor *lightForegroundColor;
	CGColorRef foregroundCGColor;
	
	int trackDuration;
	int playerPosition;
	
	iTunesEPlS playerState;

	BOOL displayPlayerPositionBar, displayPlayerPositionLabel, displayClock, clockSeconds;
}

- (id)initWithFrame:(CGRect)frame whiteBackground:(BOOL)white;

- (void)updateWithDuration:(CGFloat)duration;
- (void)updateClock;

@property (nonatomic, retain) iTunesTrack *track;
@property BOOL whiteBackground;
@property int playerPosition;
@property iTunesEPlS playerState;
@property BOOL displayPlayerPositionBar, displayPlayerPositionLabel, displayClock, clockSeconds;

@end
