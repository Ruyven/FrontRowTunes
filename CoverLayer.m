//
//  CoverLayer.m
//  FullscreenTest
//
//  Created by Alexander Decker on 14.10.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CoverLayer.h"
#import <QuartzCore/QuartzCore.h>


@implementation CoverLayer

@synthesize whiteBackground;

- (void)drawInContext:(CGContextRef)ctx {
	if (coverImage != nil) {
		[CATransaction setValue:[NSNumber numberWithFloat:0.5f] forKey:kCATransactionAnimationDuration];
		
		double gradientBrightness = whiteBackground ? 1.0 : 0.0;
		
		// context options
		CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		NSDictionary *contextOptions = [NSDictionary
		                                dictionaryWithObjectsAndKeys:(id)CFBridgingRelease(colorSpace),
		                                kCIContextWorkingColorSpace, (id)CFBridgingRelease(colorSpace),
		                                kCIContextOutputColorSpace, nil];


		CGFloat width = [self bounds].size.width;
		
		CIContext *context = [CIContext contextWithCGContext:ctx options:contextOptions];
		CIFilter *gradient = [CIFilter filterWithName:@"CILinearGradient"];
		[gradient setDefaults];
		[gradient setValue:[CIVector vectorWithX:0 Y:width*.3] forKey:@"inputPoint0"];
		[gradient setValue:[CIVector vectorWithX:0 Y:0] forKey:@"inputPoint1"];
		[gradient setValue:[CIColor colorWithRed:0 green:0 blue:0 alpha:1] forKey:@"inputColor0"];
		[gradient setValue:[CIColor colorWithRed:.3 green:.3 blue:.3 alpha:1] forKey:@"inputColor1"];
		
		CIFilter *solidBackground = [CIFilter filterWithName:@"CIConstantColorGenerator"];
		[solidBackground setValue:[CIColor colorWithRed:gradientBrightness green:gradientBrightness blue:gradientBrightness] forKey:@"inputColor"];
		
		CGSize size = coverImage.extent.size;
		[context drawImage:coverImage inRect:CGRectMake(0, 0, width, width) fromRect:CGRectMake(0, 0, size.width, size.height)];
		
		CIFilter *blended = [CIFilter filterWithName:@"CIBlendWithMask"];
		[blended setValue:coverImage forKey:@"inputImage"];
		[blended setValue:[solidBackground valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];
		[blended setValue:[gradient valueForKey:@"outputImage"] forKey:@"inputMaskImage"];

		CIFilter *transform = [CIFilter filterWithName:@"CIAffineTransform"];
		[transform setValue:[blended valueForKey:@"outputImage"] forKey:@"inputImage"];
		NSAffineTransform *affineTransform = [NSAffineTransform transform];
		[affineTransform translateXBy:0 yBy:size.height];
		[affineTransform scaleXBy:1 yBy:-1];
		[transform setValue:affineTransform forKey:@"inputTransform"];
		CIImage *flippedImage = [transform valueForKey:@"outputImage"];

		[context drawImage:flippedImage inRect:CGRectMake(0, -width, width, width) fromRect:CGRectMake(0, 0, size.width, size.height)];
	}
}

- (void)setCoverImageWithData:(NSData *)data {
	coverImage = [CIImage imageWithData:data];
}

@end