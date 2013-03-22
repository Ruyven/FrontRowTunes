//
//  RemoteController.h
//  FrontRowTunes
//
//  Created by Alexander Decker on 17.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HIDRemote.h"

@class SongView;

@interface RemoteController : NSObject <HIDRemoteDelegate> {
	HIDRemote *hidRemote;
	
	// keep a reference to SongView in order to set the prevTrack property
	SongView *songView;
}

- (void)setSongView:(SongView *)songView;

@end
