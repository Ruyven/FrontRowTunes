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

    var body: some View {
        VStack {
            Section(header: Text("Screensaver Activation").font(.title)) {
                Text("Delay before FrontRowTunes activates itself full-screen on inactivity.\nSet delay to 0 to disable automatic full-screen / activation.")
                    .font(.callout)
                
                Form {
                    VStack {
                        Slider(value: $musicDelay, in: 0...300, step: 5) {
                            Text("Music Playback Delay: \(Int(musicDelay))s")
                        }
                        Text("Time to wait while music is playing before entering full-screen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Slider(value: $clockDelay, in: 0...300, step: 5) {
                            Text("Clock Mode Delay: \(Int(clockDelay))s")
                        }
                        Text("Time to wait in clock mode before entering full-screen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(width: 450)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
