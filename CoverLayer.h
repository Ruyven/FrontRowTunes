//
//  CoverLayer.h
//  FrontRowTunes
//
//  Created by Alexander Decker on 15.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FrontRowTunes-Swift.h"

@interface CoverLayer : CALayer {
    CIImage *coverImage;
    EffectiveAppearance effectiveAppearance;
    CGColorSpaceRef colorSpace;
}

- (void)setCoverImageWithData:(NSData *)data;

@property EffectiveAppearance effectiveAppearance;

@end
