//
//  FrontRowTunesAppDelegate.h
//  FrontRowTunes
//
//  Created by Alexander Decker on 14.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"
#import "SongView.h"

#import "RemoteController.h"

@interface FrontRowTunesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	IBOutlet SongView *songView;
	
	RemoteController *remoteController;
}

@property (assign) IBOutlet NSWindow *window;

@end
