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

@interface SongView : NSView <NSWindowDelegate, LastEventTrackerDelegate>

@property (weak, nonatomic) IBOutlet NSPanel *infoPanel;

- (IBAction)toggleInfoPanel:(id)sender;

@end
