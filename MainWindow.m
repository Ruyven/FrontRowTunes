//
//  MainWindow.m
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainWindow.h"


@implementation MainWindow

// I had to subclass NSWindow and override this function so it can respond to key events even though it's borderless.
- (BOOL)canBecomeKeyWindow {
	return YES;
}

@end
