//
//  LastEventTracker.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 8/04/22.
//

import Foundation

@objc class LastEventTracker: NSObject {
    private let kCGAnyInputEventType = CGEventType(rawValue: ~0)!
    
    weak private(set) var delegate: LastEventTrackerDelegate?
    private(set) var timeout: TimeInterval = 0
    private(set) var lastTrigger = Date(timeIntervalSince1970: 0)
    
    @objc func setDelegate(_ delegate: LastEventTrackerDelegate, timeout: TimeInterval) {
        self.timeout = timeout
        self.delegate = delegate
        self.updateLastEventTime()
    }
    
    private func updateLastEventTime() {
        guard timeout > 0 && delegate != nil else {
            waitUntilNextTrigger()
            return
        }

        let timeSinceLastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: kCGAnyInputEventType)
        let timeAtLastEvent = Date(timeIntervalSinceNow: -Double(timeSinceLastEvent))
        if timeAtLastEvent.timeIntervalSince(lastTrigger) < 0 {
            waitUntilNextTrigger()
        }
        else if timeSinceLastEvent >= timeout {
            lastTrigger = Date()
            delegate?.lastEventTracker(self, timeoutPassed: timeSinceLastEvent)
            waitUntilNextTrigger()
        }
        else {
            let timeLeft = timeout - timeSinceLastEvent
            checkAgainIn(timeLeft)
        }
    }
    
    private func checkAgainIn(_ timeInterval: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.updateLastEventTime()
        }
    }
    
    private func waitUntilNextTrigger() {
        if timeout > 0 {
            checkAgainIn(timeout)
        }
    }
}

@objc protocol LastEventTrackerDelegate {
    func lastEventTracker(_ lastEventTracker: LastEventTracker, timeoutPassed: TimeInterval)
}
