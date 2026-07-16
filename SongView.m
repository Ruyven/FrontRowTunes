//
//  SongView.m
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SongView.h"

static NSString * const kDisplayPlayerPositionBarKey = @"displayPlayerPositionBar";
static NSString * const kDisplayPlayerPositionLabelKey = @"displayPlayerPositionLabel";
static NSString * const kDisplayClockKey = @"displayClock";
static NSString * const kClockSecondsKey = @"clockSeconds";
static NSString * const kAnalogClockKey = @"analogClock";
static NSString * const kAnalogClockFullScreenKey = @"analogClockFullScreen";
static NSString * const kWhiteBackgroundKey = @"whiteBackground";
static NSString * const kHasShownTutorialKey = @"hasShownTutorial";

static NSString * const kMusicScreensaverDelayKey = @"musicScreensaverDelay";
static const NSTimeInterval kDefaultMusicScreensaverDelay = 60.0;
static NSString * const kClockScreensaverDelayKey = @"clockScreensaverDelay";
static const NSTimeInterval kDefaultClockScreensaverDelay = 60.0;

@interface SongView ()
- (void)setAnalogClockFullScreen:(BOOL)value;
- (void)setAnalogClockFullScreen:(BOOL)value writeDefaults:(BOOL)writeDefaults;
- (void)setClockSeconds:(BOOL)value;
- (void)setClockSeconds:(BOOL)value writeDefaults:(BOOL)writeDefaults;
- (BOOL)isWindowReady;
@end

@implementation SongView {
    MusicTrack *currentTrack;
    
    CALayer *rootLayer;
    CALayer *infoLayer;
    SongLayer *activeSongLayer;
    SongLayer *lastSongLayer;
    AnalogClockLayer *clock;
    
    BOOL justChangedTrack;
    BOOL allowScreenChange;
    NSTimer *changeTrackTimer;
    
    BOOL firstSong;
    BOOL switchTrack;
    BOOL prevTrack;
    NSDate *prevTrackTimeStamp;
    
    int keyCode;
    int hasShownTutorial; // Use int in case we add more tutorial versions later
    BOOL whiteBackground;
    BOOL infoLayerOn;
    
    double playerPosition;
    NSTimer *updatePlayerPositionTimer;
    
    BOOL displayPlayerPositionBar, displayPlayerPositionLabel;
    BOOL displayClock, clockSeconds, analogClock, analogClockFullScreen;
    BOOL priorDisplayClock, priorAnalogClock;
    
    BOOL analogClockRequested;
    BOOL playbackRequested, nextTrackRequested;

    LastEventTracker *musicInactivityTracker;
    LastEventTracker *clockInactivityTracker;
    LastEventTracker *mouseHideTracker;
}

- (BOOL)isWindowReady {
    return self.window.isKeyWindow && self.window.isVisible;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    if (clock) {
        if (self.window) {
            [clock start];
        } else {
            [clock stop];
        }
    }
}

- (void)awakeFromNib {
    firstSong = YES;
    switchTrack = NO;
    justChangedTrack = NO;
    allowScreenChange = YES;
    
    // Register default settings
    NSDictionary *defaults = @{
        kDisplayPlayerPositionBarKey: @YES,
        kDisplayPlayerPositionLabelKey: @NO,
        kDisplayClockKey: @NO,
        kClockSecondsKey: @YES,
        kAnalogClockKey: @YES,
        kAnalogClockFullScreenKey: @NO,
        kWhiteBackgroundKey: @NO,
        kMusicScreensaverDelayKey: @(kDefaultMusicScreensaverDelay),
        kClockScreensaverDelayKey: @(kDefaultClockScreensaverDelay)
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    playerPosition = [MusicBridge getPlayerPosition];
    
    [self setupLayers];
    
    // Restore settings from NSUserDefaults
    [self setWhiteBackground:[[NSUserDefaults standardUserDefaults] boolForKey:kWhiteBackgroundKey] writeDefaults:NO];
    [self setClockSeconds:[[NSUserDefaults standardUserDefaults] boolForKey:kClockSecondsKey] writeDefaults:NO];
    [self setDisplayClock:[[NSUserDefaults standardUserDefaults] boolForKey:kDisplayClockKey] writeDefaults:NO];
    [self setAnalogClock:[[NSUserDefaults standardUserDefaults] boolForKey:kAnalogClockKey] writeDefaults:NO];
    [self setAnalogClockFullScreen:[[NSUserDefaults standardUserDefaults] boolForKey:kAnalogClockFullScreenKey] writeDefaults:NO];
    [self setDisplayPlayerPositionBar:[[NSUserDefaults standardUserDefaults] boolForKey:kDisplayPlayerPositionBarKey] writeDefaults:NO];
    [self setDisplayPlayerPositionLabel:[[NSUserDefaults standardUserDefaults] boolForKey:kDisplayPlayerPositionLabelKey] writeDefaults:NO];
    
    // Show tutorial on first launch
    hasShownTutorial = [[NSUserDefaults standardUserDefaults] integerForKey:kHasShownTutorialKey];
    if (hasShownTutorial == 0 && !_infoPanel.isVisible) {
        [self toggleInfoPanel:nil];
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kHasShownTutorialKey];
        hasShownTutorial = 1;
    }
    
    // make this view the first responder to get keystrokes
    [self.window makeFirstResponder:self];
    [self.window setDelegate:self];
    
    [self setTrack:[MusicBridge getCurrentTrack] prev:nil];
    
    // bring the window to the front
    [self.window makeKeyAndOrderFront:self];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(getTrack:) name:@"com.apple.Music.playerInfo" object:nil];
    
    updatePlayerPositionTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATEINTERVAL target:self selector:@selector(updatePlayerPosition) userInfo:nil repeats:YES];
    [self updatePlayerPosition];
    
    double delay = [[NSUserDefaults standardUserDefaults] doubleForKey:kMusicScreensaverDelayKey];
    musicInactivityTracker = [[LastEventTracker alloc] init];
    [musicInactivityTracker setDelegate:self eventType:kCGAnyInputEventType timeout:delay];
    
    delay = [[NSUserDefaults standardUserDefaults] doubleForKey:kClockScreensaverDelayKey];
    clockInactivityTracker = [[LastEventTracker alloc] init];
    [clockInactivityTracker setDelegate:self eventType:kCGAnyInputEventType timeout:delay];
    
    mouseHideTracker = [[LastEventTracker alloc] init];
    [mouseHideTracker setDelegate:self eventType:kCGEventMouseMoved timeout:2];
}

- (void)setupLayers {
    CGColorRef bgColor = whiteBackground ? CGColorCreateGenericRGB(1, 1, 1, 1) : CGColorCreateGenericRGB(0, 0, 0, 1);
    
    rootLayer = [CALayer layer];
    [rootLayer setBackgroundColor:bgColor];
    [self setLayer:rootLayer];
    [self setWantsLayer:YES];
    
    activeSongLayer = [[SongLayer alloc] initWithFrame:[self frame] whiteBackground:whiteBackground];
    activeSongLayer.playerPosition = playerPosition;
    [activeSongLayer setPlayerState:[MusicBridge getPlayerState]];
    activeSongLayer.displayPlayerPositionBar = displayPlayerPositionBar;
    activeSongLayer.displayPlayerPositionLabel = displayPlayerPositionLabel;
    activeSongLayer.displayClock = displayClock && !analogClock;
    activeSongLayer.clockSeconds = clockSeconds;
    
    
    //	[activeSongLayer setBackgroundColor:CGColorCreateGenericRGB(0, 0, 1, 1)];
    // auto-resize activeSongLayer as the view is resized
    [activeSongLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
    [rootLayer addSublayer:activeSongLayer];
    [activeSongLayer layoutIfNeeded];
    
    // cleanup
    CGColorRelease(bgColor);
    
    if (analogClock && displayClock) {
        if ([self isWindowReady]) {
            [self setUpAnalogClockIfNeeded];
        } else {
            analogClockRequested = YES;
        }
    }
}

- (void)setUpAnalogClockIfNeeded {
    if (!clock && analogClock && displayClock) {
        clock = [[AnalogClockLayer alloc] initWithDarkMode:!whiteBackground];
        if (activeSongLayer.track) {
            clock.tintColor = [activeSongLayer.track tintColorWithDarkMode:!whiteBackground strongAdjustment:true];
        } else {
            clock.tintColor = [NSColor defaultTintColor];
        }
        [rootLayer addSublayer:clock];
        clock.showSeconds = clockSeconds;
        [self updateAnalogClockLayoutWithDuration:0];
        
        if (self.window) {
            [clock start];
        }
    }
}

- (void)removeAnalogClock {
    if (clock) {
        [clock removeFromSuperlayer];
        clock = nil;
    }
}

- (void)getTrack:(NSNotification *)notification {
    MusicTrack *track = [MusicBridge getCurrentTrack];
    if (![track.id isEqualToString:currentTrack.id]) {
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
    currentTrack = track;
    if (firstSong || justChangedTrack) {
        [activeSongLayer setTrack:track];
        firstSong = NO;
        
        [self updateClockColor];
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
        [CATransaction setAnimationDuration:0.5f];
        activeSongLayer.opacity = 0;
        [CATransaction commit];
        
        [self updateClockColor];
        
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
        activeSongLayer.displayClock = displayClock && !analogClock;
        activeSongLayer.clockSeconds = clockSeconds;
        
        [rootLayer addSublayer:activeSongLayer];
        [CATransaction commit];
        
        
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

- (void)updateClockColorWithDuration:(NSTimeInterval)duration {
    if (clock) {
        [CATransaction begin];
        CATransaction.animationDuration = duration;
        
        [self updateClockColor];
        
        [CATransaction commit];
    }
}

- (void)updateClockColor {
    if (clock) {
        if (currentTrack != nil) {
            clock.tintColor = [currentTrack tintColorWithDarkMode:!whiteBackground strongAdjustment:true];
        }
        NSLog(@"analog clock tint color: %@", clock.tintColor);
        clock.darkMode = !whiteBackground;
    }
}

- (void)updateAnalogClockLayoutWithDuration:(NSTimeInterval)duration {
    if (!clock) return;
    
    [CATransaction begin];
    if (duration > 0) {
        CATransaction.animationDuration = duration;
    } else {
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    }
    
    if (analogClockFullScreen) {
        // Full-screen clock mode
        clock.position = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
        clock.zPosition = 100;
        
        CGFloat availableDiameter = MIN(self.bounds.size.width, self.bounds.size.height) * 0.82;
        CGFloat clockScale = availableDiameter / (2 * [AnalogClockLayer radius]);
        [clock setTransform:CATransform3DMakeScale(clockScale, clockScale, 1)];
    } else {
        // Compact mode
        CGFloat clockScale = self.bounds.size.height * 0.05 / [AnalogClockLayer radius];
        CGFloat scaledRadius = [AnalogClockLayer radius] * clockScale;
        
        clock.position = CGPointMake(self.bounds.size.width - 16 - scaledRadius, self.bounds.size.height - 16 - scaledRadius);
        clock.zPosition = 0;
        
        [clock setTransform:CATransform3DMakeScale(clockScale, clockScale, 1)];
    }
    
    [CATransaction commit];
}

- (void)updateClockScale {
    if (clock) {
        CGFloat clockScale = self.frame.size.height * 0.05 / [AnalogClockLayer radius];
        [clock setTransform:CATransform3DMakeScale(clockScale, clockScale, 1)];
    }
}

- (void)activateNewLayer {
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [CATransaction setValue:@0.5f forKey:kCATransactionAnimationDuration];
    if (analogClockFullScreen) {
        activeSongLayer.opacity = 0;
    } else {
        activeSongLayer.opacity = 1;
    }
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

- (void)toggleAnalogClockFullScreen {
    [self setAnalogClockFullScreen:!analogClockFullScreen];
}

#pragma mark - Setters

- (void)setDisplayPlayerPositionBar:(BOOL)value writeDefaults:(BOOL)writeDefaults {
    if (displayPlayerPositionBar == value) return;
    
    displayPlayerPositionBar = value;
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:kDisplayPlayerPositionBarKey];
    }
    
    if (activeSongLayer) {
        activeSongLayer.displayPlayerPositionBar = value;
        [activeSongLayer updateWithDuration:0.5];
    }
}

- (void)setDisplayPlayerPositionBar:(BOOL)value {
    [self setDisplayPlayerPositionBar:value writeDefaults:true];
}

- (void)setDisplayPlayerPositionLabel:(BOOL)value writeDefaults:(BOOL)writeDefaults {
    if (displayPlayerPositionLabel == value) return;
    
    displayPlayerPositionLabel = value;
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:kDisplayPlayerPositionLabelKey];
    }
    
    if (activeSongLayer) {
        activeSongLayer.displayPlayerPositionLabel = value;
        [activeSongLayer updateWithDuration:0.5];
    }
}

- (void)setDisplayPlayerPositionLabel:(BOOL)value {
    [self setDisplayPlayerPositionLabel:value writeDefaults:true];
}

- (void)setAnalogClock:(BOOL)value writeDefaults:(BOOL)writeDefaults {
    if (analogClock == value) return;
    
    analogClock = value;
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:kAnalogClockKey];
    }
    
    if (value) {
        if (displayClock) {
            if ([self isWindowReady]) {
                [self setUpAnalogClockIfNeeded];
            } else {
                analogClockRequested = YES;
            }
        }
        if (activeSongLayer) {
            activeSongLayer.displayClock = NO;
            [activeSongLayer updateClock];
            [activeSongLayer updateWithDuration:0.5];
        }
    } else {
        [self removeAnalogClock];
        if (activeSongLayer) {
            activeSongLayer.displayClock = displayClock;
            [activeSongLayer updateClock];
            [activeSongLayer updateWithDuration:0.5];
        }
    }
}

- (void)setAnalogClock:(BOOL)value {
    [self setAnalogClock:value writeDefaults:true];
}

- (void)setDisplayClock:(BOOL)value writeDefaults:(BOOL)writeDefaults {
    if (displayClock == value) return;
    
    displayClock = value;
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:kDisplayClockKey];
    }
    
    if (value) {
        if (analogClock) {
            if ([self isWindowReady]) {
                [self setUpAnalogClockIfNeeded];
            } else {
                analogClockRequested = YES;
            }
        } else {
            if (activeSongLayer) {
                activeSongLayer.displayClock = YES;
                [activeSongLayer updateClock];
                [activeSongLayer updateWithDuration:0.5];
            }
        }
    } else {
        if (analogClockFullScreen) {
            [self setAnalogClockFullScreen:NO];
        }
        [self removeAnalogClock];
        if (activeSongLayer) {
            activeSongLayer.displayClock = NO;
            [activeSongLayer updateClock];
            [activeSongLayer updateWithDuration:0.5];
        }
    }
}

- (void)setDisplayClock:(BOOL)value {
    [self setDisplayClock:value writeDefaults:true];
}

- (void)setWhiteBackground:(BOOL)value writeDefaults:(BOOL)writeDefaults {
    if (whiteBackground == value) return;
    
    whiteBackground = value;
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:kWhiteBackgroundKey];
    }
    
    [CATransaction begin];
    [CATransaction setValue:@0.5f forKey:kCATransactionAnimationDuration];
    
    CGColorRef bgColor = value ? CGColorCreateGenericRGB(1, 1, 1, 1) : CGColorCreateGenericRGB(0, 0, 0, 1);
    [rootLayer setBackgroundColor:bgColor];
    CGColorRelease(bgColor);
    
    if (activeSongLayer) {
        [activeSongLayer setWhiteBackground:value];
        [activeSongLayer updateWithDuration:0.5];
    }
    
    [self updateClockColorWithDuration:0.5];
    
    [CATransaction commit];
}

- (void)setWhiteBackground:(BOOL)value {
    [self setWhiteBackground:value writeDefaults:true];
}

- (void)setAnalogClockFullScreen:(BOOL)value writeDefaults:(BOOL)writeDefaults {
    if (analogClockFullScreen == value) return;
    
    analogClockFullScreen = value;
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:kAnalogClockFullScreenKey];
    }
    
    if (value) {
        // Entering Full-Screen
        priorDisplayClock = displayClock;
        priorAnalogClock = analogClock;
        
        displayClock = YES;
        analogClock = YES;
        
        if ([self isWindowReady]) {
            [self setUpAnalogClockIfNeeded];
        } else {
            analogClockRequested = YES;
        }
        if (clock) {
            clock.showSeconds = clockSeconds;
        }
        
        if (activeSongLayer) {
            [CATransaction begin];
            [CATransaction setAnimationDuration:0.5f];
            activeSongLayer.opacity = 0;
            [CATransaction commit];
            
            activeSongLayer.displayClock = NO;
        }
        [self updateAnalogClockLayoutWithDuration:0.5];
    } else {
        // Leaving Full-Screen
        displayClock = priorDisplayClock;
        analogClock = priorAnalogClock;
        
        if (activeSongLayer) {
            activeSongLayer.displayClock = displayClock && !analogClock;
            activeSongLayer.clockSeconds = clockSeconds;
        }
        
        if (analogClock && displayClock) {
            [self updateAnalogClockLayoutWithDuration:0.5];
            if (clock) {
                clock.showSeconds = clockSeconds;
            }
        } else {
            [self removeAnalogClock];
        }
        
        if (activeSongLayer) {
            [CATransaction begin];
            [CATransaction setAnimationDuration:0.5f];
            activeSongLayer.opacity = 1;
            [CATransaction commit];
            
            [activeSongLayer updateClock];
            [self updateClockColorWithDuration:0.5];
            [activeSongLayer updateWithDuration:0.5];
        }
    }
}

- (void)setAnalogClockFullScreen:(BOOL)value {
    [self setAnalogClockFullScreen:value writeDefaults:true];
}

- (void)setClockSeconds:(BOOL)value writeDefaults:(BOOL)writeDefaults {
    if (clockSeconds == value) return;
    
    clockSeconds = value;
    if (writeDefaults) {
        [[NSUserDefaults standardUserDefaults] setBool:value forKey:kClockSecondsKey];
    }
    
    if (clock) {
        clock.showSeconds = value;
    }
    if (activeSongLayer) {
        activeSongLayer.clockSeconds = value;
    }
}

- (void)setClockSeconds:(BOOL)value {
    [self setClockSeconds:value writeDefaults:true];
}

- (void)handlePlaybackRequest {
    playbackRequested = YES;
    
    __weak typeof(self) weakSelf = self;
    [MusicBridge playInBackgroundWithCompletion:^{
        // Once Music app is running, this returns - but for some reason,
        // Music app doesn't automatically start playback, so we retry once.
        [weakSelf retryPlayback];
    }];
}

- (void)retryPlayback {
    if (!playbackRequested) {
        return;
    }
    if ([MusicBridge isMusicRunning] && [MusicBridge isMusicPlaying]) {
        playbackRequested = NO;
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    if ([MusicBridge getCurrentTrack] == nil) {
        // Workaround: if Music was just launched and isn't active,
        // telling it to play isn't working - but we can tell it to
        // select a track, then play.
        [MusicBridge nextTrack];
    }
    [MusicBridge playInBackgroundWithCompletion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self->playbackRequested = NO;
    }];
}

- (void)handleNextTrackRequest {
    nextTrackRequested = YES;
    __weak typeof(self) weakSelf = self;
    [MusicBridge nextTrackInBackgroundWithCompletion:^{
        [weakSelf retryNextTrack];
    }];
}

- (void)retryNextTrack {
    if (!nextTrackRequested) {
        return;
    }
    if ([MusicBridge getCurrentTrack] != nil) {
        nextTrackRequested = NO;
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [MusicBridge nextTrackInBackgroundWithCompletion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self->nextTrackRequested = NO;
    }];
}

- (void)keyDown:(NSEvent *)event {
    NSString *character = [event characters];
    NSString *charactersIgnoringModifiers = [event charactersIgnoringModifiers];
    NSEventModifierFlags modifierFlags = [event modifierFlags];
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
        if (activeSongLayer.isSplashScreen) {
            activeSongLayer.loadingMessage = @"Starting playback...";
            [activeSongLayer updateWithDuration:.2];
        }
        if ([MusicBridge isMusicRunning]) {
            [MusicBridge playpause];
        } else {
            [self handlePlaybackRequest];
        }
	} else if ([charactersIgnoringModifiers isEqualToString:@"t"] || [charactersIgnoringModifiers isEqualToString:@"T"]) {
        if ((modifierFlags & NSEventModifierFlagOption) != 0) {
            [self toggleAnalogClockFullScreen];
        } else if ([character isEqualToString:@"T"]) {
            [self setDisplayClock:!displayClock];
        } else if ([character isEqualToString:@"t"]) {
            if (analogClockFullScreen) {
                [self setClockSeconds:!clockSeconds];
            } else if (!displayClock) {
                [self setDisplayClock:true];
            } else {
                
                if (analogClock && clockSeconds) {
                    [self setClockSeconds:false];
                } else if (analogClock && !clockSeconds) {
                    [self setAnalogClock:false];
                } else if (!analogClock && !clockSeconds) {
                    [self setClockSeconds:true];
                } else { // (!analogClock && clockSeconds)
                    [self setAnalogClock:true];
                }
                
                activeSongLayer.displayClock = displayClock && !analogClock;
                [activeSongLayer updateClock];
                [activeSongLayer updateWithDuration:.5];
            }
            [activeSongLayer updateClock];
            [activeSongLayer updateWithDuration:.5];
        }
/*	} else if (keyCode == 123 || keyCode == 124) {
		switchTrack = YES;*/
		// ToDo: bei langem drücken spulen, ansonsten nextTrack bzw. backTrack
		// oder einfach wie Music app lassen: beim keyDown nextTrack bzw. backTrack
//		[NSTimer 
		// 123 = previous, 124 = next
//		[MusicBridge backTrack];
	} else if (keyCode == 123) {
        // left arrow
		if (activeSongLayer.isSplashScreen) {
            activeSongLayer.loadingMessage = @"No previous track";
            [activeSongLayer updateWithDuration:.2];
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(resetLoadingMessage) userInfo:nil repeats:NO];
        } else {
            self.prevTrack = YES;
            [MusicBridge backTrack];
        }
	} else if (keyCode == 124) {
        // right arrow
		if (activeSongLayer.isSplashScreen) {
            activeSongLayer.loadingMessage = @"Loading next track...";
            [activeSongLayer updateWithDuration:.2];
        }
        self.prevTrack = NO;
        if ([MusicBridge isMusicRunning]) {
            [MusicBridge nextTrack];
        } else {
            [self handleNextTrackRequest];
        }
	} else if ([character isEqualToString:@"q"] || [character isEqualToString:@"Q"]) {
		[NSApp terminate:self];
/*	} else if ([character isEqualToString:@"h"]) {
		[NSApp hide:self]; // doesn't seem to work.*/
	} else if (keyCode == 36) {			// Return
        if (!displayPlayerPositionBar && !displayPlayerPositionLabel) {
            [self setDisplayPlayerPositionBar:true];
        } else if (displayPlayerPositionBar && !displayPlayerPositionLabel) {
            [self setDisplayPlayerPositionLabel:true];
        } else if (displayPlayerPositionBar && displayPlayerPositionLabel) {
            [self setDisplayPlayerPositionBar:false];
        } else {
            [self setDisplayPlayerPositionBar:true];
            [self setDisplayPlayerPositionLabel:false];
        }
        [activeSongLayer setDisplayPlayerPositionLabel:displayPlayerPositionLabel];
        [activeSongLayer updateWithDuration:.5];
    } else if (keyCode == 76) {			// fn+Return or Enter
        if (!displayPlayerPositionBar && !displayPlayerPositionLabel) {
            [self setDisplayPlayerPositionBar:true];
        } else {
            [self setDisplayPlayerPositionBar:false];
            [self setDisplayPlayerPositionLabel:false];
        }
        [activeSongLayer setDisplayPlayerPositionLabel:displayPlayerPositionLabel];
        [activeSongLayer updateWithDuration:.5];
    } else if ([character isEqualToString:@"w"]) {
        [self setWhiteBackground:YES];
    } else if ([character isEqualToString:@"b"]) {
        [self setWhiteBackground:NO];
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
            if ([songID isEqualToString:currentTrack.id]) {
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

- (void)resetLoadingMessage {
    if (playbackRequested || nextTrackRequested) {
        return;
    }
    activeSongLayer.loadingMessage = nil;
    [activeSongLayer updateWithDuration:.2];
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

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    [mouseHideTracker resetTrigger];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [mouseHideTracker resetTrigger];
    
    if (analogClockRequested) {
        if (clock) {
            [clock start];
        } else {
            [self setUpAnalogClockIfNeeded];
        }
        analogClockRequested = NO;
    }
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [self updateAnalogClockLayoutWithDuration:0];
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp terminate:self];
}

#pragma mark

- (bool)isWindowFullScreen {
    return ([self.window styleMask] & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen;
}

- (void)lastEventTracker:(LastEventTracker *)lastEventTracker timeoutPassed:(NSTimeInterval)timeoutPassed {
    if (lastEventTracker == musicInactivityTracker) {
        [self handleMusicInactivityTimeout];
    } else if (lastEventTracker == clockInactivityTracker) {
        [self handleClockInactivityTimeout];
    } else if (lastEventTracker == mouseHideTracker) {
        [self handleMouseInactivity];
    }
}

- (void)handleMusicInactivityTimeout {
    if ([MusicBridge getPlayerState] == MusicBridge.PLAYER_STATE_PLAYING) {
        [self enterScreensaverIfRequired];
    }
}

- (void)handleClockInactivityTimeout {
    if (analogClockFullScreen) {
        [self enterScreensaverIfRequired];
    }
}

- (void)enterScreensaverIfRequired {
    if ([self isWindowFullScreen]) {
        if (![NSApp isActive]) {
            [NSApp activateIgnoringOtherApps:true];
            [self.window makeKeyAndOrderFront:self];
        }
    } else {
        [self.window toggleFullScreen:self];
    }
}

- (void)handleMouseInactivity {
    if ([self isWindowFullScreen]) {
        [NSCursor setHiddenUntilMouseMoves:true];
    }
}

@end
