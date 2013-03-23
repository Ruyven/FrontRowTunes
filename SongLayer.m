//
//  SongLayer.m
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SongLayer.h"


@implementation SongLayer

@synthesize track;
@synthesize whiteBackground;
@synthesize playerPosition;
@synthesize playerState;

@synthesize displayPlayerPositionBar;
@synthesize displayPlayerPositionLabel;
@synthesize displayClock;
@synthesize clockSeconds;

- (id)initWithFrame:(CGRect)frame whiteBackground:(BOOL)white {
	if (self = [super init]) {
		[self setFrame:frame];

		songInfoTextLayer = [CATextLayer layer];
		songInfoTextLayer.wrapped = YES;
		songInfoTextLayer.anchorPoint = CGPointMake(0, 1);
		[self addSublayer:songInfoTextLayer];

		trackDurationLayer = [CALayer layer];
		trackDurationLayer.borderWidth = 2.0;
		playerPositionLayer = [CALayer layer];
		[self addSublayer:trackDurationLayer];
		[trackDurationLayer addSublayer:playerPositionLayer];
		
		timePassedLayer = [CATextLayer layer];
		timePassedLayer.alignmentMode = kCAAlignmentLeft;
		timePassedLayer.font = CFBridgingRetain(@"Lucida-Grande");
		timePassedLayer.bounds = CGRectMake(0, 0, 500, 50);
		timePassedLayer.anchorPoint = CGPointMake(0, 1);
		timePassedLayer.opaque = NO;
		[self addSublayer:timePassedLayer];

		timeRemainingLayer = [[CATextLayer alloc] initWithLayer:timePassedLayer];
		timeRemainingLayer.alignmentMode = kCAAlignmentRight;
		timeRemainingLayer.font = CFBridgingRetain(@"Lucida-Grande");
		timeRemainingLayer.anchorPoint = CGPointMake(1, 1);
		timeRemainingLayer.bounds = CGRectMake(-500, 0, 500, 50);
		[self addSublayer:timeRemainingLayer];
		
		coverLayer = [[CoverLayer alloc] init]; // so that init gets called (see CoverLayer.m)
		[self addSublayer:coverLayer];

		// Cover dreidimensional drehen
		CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
		rotationAndPerspectiveTransform.m34 = -1. / 850;
		rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, 10 * M_PI / 180.0f, 0.0f, 1.0f, 0.0f);
		//	rotationAndPerspectiveTransform = CATransform3DScale(rotationAndPerspectiveTransform, 1.5, 1.5, 1);
		coverLayer.transform = rotationAndPerspectiveTransform;
        coverLayer.zPosition = -999;

		pauseLayer = [CALayer layer];
		[pauseLayer addSublayer:[CALayer layer]];
		[pauseLayer addSublayer:[CALayer layer]];
		[self addSublayer:pauseLayer];

		clockLayer = [CATextLayer layer];
		clockLayer.alignmentMode = kCAAlignmentLeft;
		clockLayer.font = CFBridgingRetain(@"Lucida-Grande");
		clockLayer.anchorPoint = CGPointMake(0, 1);
		clockLayer.bounds = CGRectMake(-500, 0, 500, 100);
		[self updateClock];
		[self addSublayer:clockLayer];
		
		
		[self setWhiteBackground:white];
		[self updateWithDuration:0.1];
	}
	return self;
}

- (void)updateWithDuration:(CGFloat)duration {
	if (duration == 0.0) {
		[CATransaction setValue:(id) kCFBooleanTrue forKey:kCATransactionDisableActions];
	}
	else {
		[CATransaction setValue:@(duration) forKey:kCATransactionAnimationDuration];
	}



	CGFloat width = self.bounds.size.width;
	CGFloat height = self.bounds.size.height;

	NSMutableDictionary *songnameAttributes = [[NSMutableDictionary alloc] init];
	songnameAttributes[NSFontAttributeName] = [NSFont fontWithName:@"Lucida Grande Bold" size:height * .06];
	songnameAttributes[NSForegroundColorAttributeName] = foregroundColor;
//	[songnameAttributes setObject:[NSColor whiteColor] forKey:NSBoldFontMask];


	NSMutableDictionary *artistAttributes = [[NSMutableDictionary alloc] init];
	artistAttributes[NSFontAttributeName] = [NSFont fontWithName:@"Lucida Grande" size:height * .04];
	artistAttributes[NSForegroundColorAttributeName] = lightForegroundColor;
    
	NSMutableDictionary *ratingAttributes = [[NSMutableDictionary alloc] init];
	ratingAttributes[NSFontAttributeName] = [NSFont fontWithName:@"Lucida Grande" size:height * .04];
	ratingAttributes[NSForegroundColorAttributeName] = foregroundColor;

//	songnameAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:NSFontAttributeName, [NSFont fontWithName:@"Lucida Grande" size:height*0.05], NSForegroundColorAttributeName, [NSColor whiteColor], nil];
//	artistAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:NSFontAttributeName, [NSFont fontWithName:@"Lucida Grande" size:height*0.04], NSForegroundColorAttributeName, [NSColor colorWithCalibratedHue:0 saturation:0 brightness:.9 alpha:0], nil];

//	CGColorRef whiteColor = CGColorCreateGenericRGB(1, 1, 1, 1);

	if ([track name] == nil) {
		// no track playing! (is there a better way to check that?)
		NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Playback stopped." attributes:songnameAttributes];
		songInfoTextLayer.bounds = CGRectMake(0, 0, width * .8, height / 2);
		songInfoTextLayer.position = CGPointMake(width * .1, height * .53); // adjust y-position if the fontSize is changed
		songInfoTextLayer.alignmentMode = kCAAlignmentCenter;
		songInfoTextLayer.string = string;
	}
	else if (track != nil) {
		// display track info
		if (coverExists) {
			songInfoTextLayer.bounds = CGRectMake(0, 0, width * .5, height / 2);
			songInfoTextLayer.position = CGPointMake(width * .48, height * .7);
			songInfoTextLayer.alignmentMode = kCAAlignmentNatural;
		}
		else {
			songInfoTextLayer.bounds = CGRectMake(0, 0, width * .9, height / 2);
			songInfoTextLayer.position = CGPointMake(width * .05, height * .7);
			songInfoTextLayer.alignmentMode = kCAAlignmentCenter;
		}
		NSAttributedString *doubleLinebreak = [[NSAttributedString alloc] initWithString:@"\n\n"];
//		NSAttributedString *tripleLinebreak = [[NSAttributedString alloc] initWithString:@"\n\n\n"];
		NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[track name] attributes:songnameAttributes];
		[string appendAttributedString:doubleLinebreak];
		//[string appendAttributedString:doubleLinebreak];
		[string appendAttributedString:[[NSAttributedString alloc] initWithString:[track artist] attributes:artistAttributes]];
		[string appendAttributedString:doubleLinebreak];
		[string appendAttributedString:[[NSAttributedString alloc] initWithString:[track album] attributes:artistAttributes]];
        [string appendAttributedString:doubleLinebreak];
        [string appendAttributedString:doubleLinebreak];
        
        NSMutableString *ratingString = [[NSMutableString alloc] init];
        
        for (int i = 0; i < 100; i+=20) {
            if (i < track.rating) {
                [ratingString appendString:@"★"];
            } else {
                [ratingString appendString:@"☆"];
            }
        }
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:ratingString attributes:ratingAttributes]];

		songInfoTextLayer.string = string;

		//coverLayer.bounds = CGRectMake(0, -300, 300, 900);
		//coverLayer.position = CGPointMake(300, 400);
		CGFloat coverWidth = width * .35;

		coverLayer.bounds = CGRectMake(0, -coverWidth, coverWidth, 3 * coverWidth);
		coverLayer.anchorPoint = CGPointMake(.5, .5);
		coverLayer.position = CGPointMake(width * .25, height * .5);
		[coverLayer setNeedsDisplay];

		durationLayerHeight = height * .05;
		durationLayerYPosition = height * .05;
		if (displayPlayerPositionLabel) durationLayerYPosition = height * .08;
		CGFloat layerDiameter = durationLayerHeight - 6;
		CGFloat layerWidth = width * .9;
		trackDurationLayer.bounds = CGRectMake(0, 0, layerWidth, durationLayerHeight);
		trackDurationLayer.position = CGPointMake(width / 2, durationLayerYPosition);
		trackDurationLayer.cornerRadius = durationLayerHeight / 2.;
		trackDurationLayer.borderColor = foregroundCGColor;

		playerPositionLayer.bounds = CGRectMake(0, 0, layerDiameter, layerDiameter);
		playerPositionLayer.cornerRadius = layerDiameter / 2.;
		playerPositionLayer.backgroundColor = foregroundCGColor;

		// update the position of playerPositionLayer
		trackDuration = [track duration];
		[self setPlayerPosition:playerPosition];
		
		if (clockSeconds) {
			clockLayer.position = CGPointMake(width*.85, height);
		} else {
			clockLayer.position = CGPointMake(width*.9, height);
		}

		// pause icon
		CALayer *pausePart1 = [pauseLayer sublayers][0];
		CALayer *pausePart2 = [pauseLayer sublayers][1];
		pausePart1.backgroundColor = foregroundCGColor;
		pausePart2.backgroundColor = foregroundCGColor;
		pausePart1.bounds = CGRectMake(0, 0, layerDiameter * .4, layerDiameter);
		pausePart2.bounds = CGRectMake(0, 0, layerDiameter * .4, layerDiameter);
		pausePart1.position = CGPointMake(0, 0);
		pausePart2.position = CGPointMake(layerDiameter * .6, 0);
		pauseLayer.frame = CGRectMake(trackDurationLayer.frame.origin.x, durationLayerYPosition, layerDiameter, layerDiameter);
		
		if (playerState == iTunesEPlSPaused || playerState == iTunesEPlSStopped) {
			pauseLayer.opacity = 1;
			CGRect old = trackDurationLayer.frame;
			CGFloat moveBy = layerDiameter * 1.2;
			trackDurationLayer.frame = CGRectMake(old.origin.x + moveBy, old.origin.y, old.size.width - moveBy, old.size.height);
		}
		else {
			pauseLayer.opacity = 0;
			// I have better things to do now than to find out why it doesn't work otherwise
		}
		

		if (trackDuration != 0 &&
			(displayPlayerPositionBar || 
			(!displayPlayerPositionLabel && (playerState == iTunesEPlSFastForwarding || playerState == iTunesEPlSRewinding)))) {
			
			trackDurationLayer.opacity = 1;
			
			timePassedLayer.position = CGPointMake(trackDurationLayer.frame.origin.x + width*.01, height*.05);
			timeRemainingLayer.position = CGPointMake(width * .94, height * .05);
		}
		else {
			trackDurationLayer.opacity = 0;
			timePassedLayer.position = CGPointMake(height*.05, height*.05);
			timeRemainingLayer.position = CGPointMake(width - height*.05, height*.05);
		}
		
		if (trackDuration != 0 && displayPlayerPositionLabel) {
			timePassedLayer.foregroundColor = timeRemainingLayer.foregroundColor = foregroundCGColor;
			timePassedLayer.fontSize = timeRemainingLayer.fontSize = height * .03;
			
			timePassedLayer.opacity = timeRemainingLayer.opacity = 1;
		} else {
			timePassedLayer.opacity = timeRemainingLayer.opacity = 0;
			
//			timePassedLayer.position = CGPointMake(width*.05, height*.05);
//			timeRemainingLayer.position = CGPointMake(width * .95, height * .05); // für's einblenden
		}
		
		clockLayer.fontSize = height * .05;
		if (displayClock) {
			clockLayer.foregroundColor = foregroundCGColor;
			clockLayer.opacity = 1;
		} else {
			clockLayer.opacity = 0;
		}
	}


//	CGColorRelease(whiteColor);

	[self layoutIfNeeded];
}

- (void)setTrack:(iTunesTrack *)thetrack {
	track = thetrack;

	// update cover
	SBElementArray *trackArtworks = [track artworks];
	if ([trackArtworks count] > 0) {
		coverLayer.opacity = 1;
		[coverLayer setCoverImageWithData:[trackArtworks[0] rawData]];
		coverExists = YES;
	}
	else {
		coverLayer.opacity = 0;
		coverExists = NO;
	}

	[self updateWithDuration:0.5];
}

- (void)dealloc {
	CGColorRelease(foregroundCGColor); // is that necessary? Or rather: should I do that every time I create a new foregroundCGColor?
	// ToDo: is there anything else that needs to be released?
}

- (void)setWhiteBackground:(BOOL)white {
	[coverLayer setWhiteBackground:white];
	if (white) {
		backgroundColor = [NSColor whiteColor];
		foregroundColor = [NSColor blackColor];
		lightForegroundColor = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:.4 alpha:1];
		foregroundCGColor = CGColorCreateGenericRGB(0, 0, 0, 1);
	}
	else {
		backgroundColor = [NSColor blackColor];
		foregroundColor = [NSColor whiteColor];
		lightForegroundColor = [NSColor colorWithCalibratedHue:0 saturation:0 brightness:.8 alpha:1];
		foregroundCGColor = CGColorCreateGenericRGB(1, 1, 1, 1);
	}
}

- (void)setPlayerState:(iTunesEPlS)newPlayerState {
	if (playerState != newPlayerState) {
		playerState = newPlayerState;
		if ([track name] != nil) {
			if (playerState == iTunesEPlSPaused || playerState == iTunesEPlSStopped) {
				// if changing to a new track while paused, the player state will be 'stopped'!
				[CATransaction setAnimationDuration:2.0f];
				[pauseLayer setOpacity:1];
			}
			else {
				[pauseLayer setOpacity:0];
			}
		}
		[self updateWithDuration:0.5];
	}
}

- (void)updateClock {
	NSDate *now = [NSDate date];
	// ToDo: hier je nach Land anpassen
	if (clockSeconds) {
		clockLayer.string = [now descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil];
	} else {
		clockLayer.string = [now descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil];
	}
}

- (void)setPlayerPosition:(int)newPlayerPosition {
	playerPosition = newPlayerPosition;
	
	if (trackDuration == 0) return;
	

	[CATransaction begin];
	[CATransaction setAnimationDuration:.4];

	CGFloat minX = durationLayerHeight / 2.;
	CGFloat maxX = trackDurationLayer.bounds.size.width - minX;
	CGFloat xPosition = (maxX - minX) * (double)playerPosition / trackDuration + minX;
	playerPositionLayer.position = CGPointMake(xPosition, durationLayerHeight / 2.);

	[CATransaction commit];


	int minutes = playerPosition / 60; // Ganzzahldivision
	int seconds = playerPosition % 60;
	timePassedLayer.string = [NSString stringWithFormat:@"%d:%02d",minutes,seconds];
	
	int remainingTime = trackDuration - playerPosition;
	minutes = remainingTime / 60;
	seconds = remainingTime % 60;
	timeRemainingLayer.string = [NSString stringWithFormat:@"-%d:%02d",minutes,seconds];
	
	[timeRemainingLayer setNeedsDisplay]; // warum auch immer das nötig ist...
}

- (BOOL)needsDisplayOnBoundsChange {
	return YES; // invoke setNeedsDisplay (->drawInContext) when bounds change
}

- (void)drawInContext:(CGContextRef)ctx {
	[self updateWithDuration:0.0];
}

@end