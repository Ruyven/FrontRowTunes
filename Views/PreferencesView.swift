//
//  PreferencesView.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 17/07/26.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage(PrefKeys.musicScreensaverDelay) var musicDelay: Double = 60
    @AppStorage(PrefKeys.clockScreensaverDelay) var clockDelay: Double = 60
    
    var mainPadding: CGFloat = 4
    
    var body: some View {
        Form {
            Section(header: Text("Screensaver Mode").font(.title)) {
                Text("In screensaver mode, FrontRowTunes activates itself full-screen on inactivity.\nSet either delay to 0 to disable that screensaver mode condition.")
                    .font(.callout)
                    .padding(.bottom, mainPadding)
                
                HStack {
                    Text("Music Playback Delay")
                    Spacer()
                    Text(musicDelay > 0 ? "\(Int(musicDelay))s" : "Disabled")
                }
                
                Slider(value: $musicDelay, in: 0...300, step: 5)
                
                Text("Time to wait while music is playing before entering screensaver mode.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, mainPadding)
                
                
                HStack {
                    Text("Full-Sized Clock Mode Delay")
                    Spacer()
                    Text(clockDelay > 0 ? "\(Int(clockDelay))s" : "Disabled")
                }
                
                Slider(value: $clockDelay, in: 0...300, step: 5)
                
                Text("Time to wait in full-sized clock mode (option+T) before entering screensaver mode.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            }
        }
        .padding()
        .frame(width: 480)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
