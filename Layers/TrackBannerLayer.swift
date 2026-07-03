//
//  TrackBannerLayer.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 3/07/26.
//

import Foundation
import QuartzCore
import AppKit

@objc class TrackBannerLayer: CALayer {
    private let artLayer = CALayer()
    private let textLayer = CATextLayer()

    @objc override init() {
        super.init()
        NSLog("TrackBannerLayer: init called");
        setupLayers()
    }

    @objc override init(layer: Any) {
        super.init(layer: layer)
        if let layer = layer as? TrackBannerLayer {
            // If copying a TrackBannerLayer, copy the sublayers or setup again
            // For now, re-setup is sufficient for simple usage
            setupLayers()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        self.needsDisplayOnBoundsChange = true
        artLayer.contentsGravity = .resizeAspectFill
        textLayer.fontSize = 20
        textLayer.foregroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        textLayer.alignmentMode = .center
        
        self.addSublayer(artLayer)
        self.addSublayer(textLayer)
        
        // Ensure sublayers have an initial frame
        self.layoutSublayers()
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        
        let artSize = self.bounds.size.height
        let textWidth: CGFloat = 400 // Approximate width, or calculate based on string
        let spacing: CGFloat = 10
        let totalWidth = artSize + spacing + textWidth
        let startX = (self.bounds.size.width - totalWidth) / 2
        
        artLayer.frame = CGRect(x: startX, y: 0, width: artSize, height: artSize)
        textLayer.frame = CGRect(x: startX + artSize + spacing, y: 0, width: textWidth, height: artSize)
    }

    @objc func update(with track: MusicTrack?) {
        if let track = track {
            textLayer.string = "\(track.artist) - \(track.name)"
            if let artData = track.artwork, let image = NSImage(data: artData) {
                artLayer.contents = image
            } else {
                artLayer.contents = MusicTrack.defaultArtwork
            }
        } else {
            textLayer.string = ""
            artLayer.contents = nil
        }
    }
}
