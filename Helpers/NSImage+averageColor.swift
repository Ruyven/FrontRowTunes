//
//  NSImage+averageColor.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 12/04/22.
//

import Cocoa

@objc extension NSImage {
    /// Returns the average color that is present in the image.
    @objc var averageColor: NSColor? {
        // Image is not valid, so we cannot get the average color
        if !isValid {
            return nil
        }
        
        // Create a CGImage from the NSImage
        var imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let cgImageRef = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        
        // Create vector and apply filter
        let inputImage = CIImage(cgImage: cgImageRef!)
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector])
        let outputImage = filter!.outputImage!

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return NSColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension NSColor {
    /// Adjusts the brightness
    func adjustingHSBA(_ adjustValues: (inout CGFloat, inout CGFloat, inout CGFloat, inout CGFloat) ->Bool) -> NSColor {
        var hue = hueComponent
        var saturation = saturationComponent
        var brightness = brightnessComponent
        var alpha = alphaComponent
        
        if adjustValues(&hue, &saturation, &brightness, &alpha) {
            return NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        } else {
            return self
        }
    }
}
