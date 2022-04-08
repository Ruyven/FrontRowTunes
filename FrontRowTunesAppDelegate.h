//
//  FrontRowTunesAppDelegate.h
//  FrontRowTunes
//
//  Created by Alexander Decker on 14.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SongView.h"


#import <IOKit/pwr_mgt/IOPMLib.h> // display sleep prevention

@interface FrontRowTunesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *__weak window;
	IBOutlet SongView *songView;
    
    IOPMAssertionID assertionID; // display sleep prevention
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *infoTextField;

@end
