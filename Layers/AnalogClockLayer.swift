//
//  AnalogClockLayer.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 9/04/22.
//

import Foundation
import Cocoa

fileprivate let animationDuration: TimeInterval = 20


class AnalogClockLayer: CALayer {
    @objc static let radius: CGFloat = 200
    
    @objc var darkMode: Bool {
        didSet {
            updateClockFace()
            updateClockHands()
        }
    }
    
    @objc init(darkMode: Bool) {
        self.darkMode = darkMode
        super.init()
        
        self.bounds = CGRect(x: 0, y: 0, width: 2*Self.radius, height: 2*Self.radius)
        
        setUpClockFace()
        setUpClockHands()
        
        DispatchQueue.main.async {
            self.updateAnimations()
        }
    }
    
    @objc override convenience init(layer: Any) {
        if let clockLayer = layer as? AnalogClockLayer {
            self.init(darkMode: clockLayer.darkMode)
        } else {
            self.init(darkMode: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc var tintColor: NSColor? {
        didSet {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.5)
            secondHand.backgroundColor = tintColor?.cgColor
            CATransaction.commit()
        }
    }
    
    private func setUpClockFace() {
        for minute in 0..<60 {
            let height: CGFloat = {
                let radius = Self.radius
                if minute % 15 == 0 {
                    return radius * 0.2
                } else if minute % 5 == 0 {
                    return radius * 0.1
                } else {
                    return radius * 0.05
                }
            }()
            let width = min(height / 2, Self.radius * 0.075)
            setUpFaceTick(
                width: width,
                height: height,
                rotation: CGFloat(minute)
            )
        }
        updateClockFace()
    }
    
    private var tickLayers = [CALayer]()
    
    private func setUpFaceTick(width: CGFloat, height: CGFloat, rotation: CGFloat) {
        let tickLayer = CALayer()
        tickLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        tickLayer.cornerRadius = width / 2
        
        tickLayer.anchorPoint = CGPoint(x: 0.5, y: -(Self.radius - height + width/2) / height)
        tickLayer.position = CGPoint(x: Self.radius, y: Self.radius)
        tickLayer.transform = CATransform3DMakeRotation(-rotation / 60 * 2 * .pi, 0, 0, 1)
        
        self.addSublayer(tickLayer)
        self.tickLayers.append(tickLayer)
    }
    
    private func updateClockFace() {
        let foregroundColor = darkMode ? CGColor.white : CGColor.black
        for tickLayer in tickLayers {
            tickLayer.backgroundColor = foregroundColor
        }
    }
    
    private func setUpClockHands() {
        let radius = Self.radius
        
        let handWidth: CGFloat = Self.radius * 0.07
        let handCornerRadius = handWidth / 2
        
        let hourHeight = radius * 0.6
        hourHand.bounds = CGRect(x: 0, y: 0, width: handWidth, height: hourHeight + handCornerRadius)
        hourHand.cornerRadius = handCornerRadius
        hourHand.anchorPoint = CGPoint(x: 0.5, y: handCornerRadius / hourHeight)
        self.addSublayer(hourHand)
        hourHand.position = CGPoint(x: radius, y: radius)
        
        let minuteHeight = radius * 0.92
        minuteHand.bounds = CGRect(x: 0, y: 0, width: handWidth, height: minuteHeight + handCornerRadius)
        minuteHand.cornerRadius = handCornerRadius
        minuteHand.anchorPoint = CGPoint(x: 0.5, y: handCornerRadius / minuteHeight)
        self.addSublayer(minuteHand)
        minuteHand.position = CGPoint(x: radius, y: radius)
        
        secondHand.bounds = CGRect(x: 0, y: 0, width: 2, height: Self.radius)
        secondHand.anchorPoint = CGPoint(x: 0.5, y: 0)
        self.addSublayer(secondHand)
        secondHand.position = CGPoint(x: radius, y: radius)
        
        let (hour, minute, second) = getHourMinuteSecond(getTime(timeIntervalSinceNow: 0))
        setHourHandRotation(hourHand, hour)
        setHandRotation(minuteHand, minute)
        setHandRotation(secondHand, second)
        
        updateClockHands()
    }
    
    private func updateClockHands() {
        let foregroundColor = darkMode ? CGColor.white : CGColor.black
        hourHand.backgroundColor = foregroundColor
        minuteHand.backgroundColor = foregroundColor
    }
    
    // MARK: - Animations
    
    func updateAnimations() {
        setTime(getTime(timeIntervalSinceNow: animationDuration), animationDuration: animationDuration) { [weak self] in self?.updateAnimations() }
    }
    
    private let secondHand = CALayer()
    private let minuteHand = CALayer()
    private let hourHand = CALayer()
    
    private func getHourMinuteSecond(_ time: Double) -> (Double, Double, Double) {
        var hour = time / 3600
        if hour > 12 { hour -= 12 }
        let minute = (time / 60).truncatingRemainder(dividingBy: 60)
        let second = time.truncatingRemainder(dividingBy: 60)
        return (hour, minute, second)
    }
    
    private func setTime(_ time: Double, animationDuration: TimeInterval, completion: @escaping () -> ()) {
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear))
        CATransaction.setCompletionBlock({
//            NSLog("calling completion after animation duration \(animationDuration)")
            completion()
        })

        if animationDuration > 0 {
//            NSLog("set animation duration to \(animationDuration)")
            CATransaction.setAnimationDuration(animationDuration)
        } else {
            CATransaction.disableActions()
        }
        
        let (hour, minute, second) = getHourMinuteSecond(time)
        
        setHourHandRotation(hourHand, hour)
        setHandRotation(minuteHand, minute)
        setHandRotation(secondHand, second)
        
        CATransaction.commit()
    }
    
    private func setHandRotation(_ hand: CALayer, _ rotation: CGFloat) {
        let angle = -rotation * 2 * CGFloat.pi / 60
//        NSLog("set hand to \(rotation)")
        hand.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
    }
    
    private func setHourHandRotation(_ hand: CALayer, _ rotation: CGFloat) {
        let angle = -rotation * 2 * CGFloat.pi / 12
        hand.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
    }
    
    private func getTime(timeIntervalSinceNow: TimeInterval) -> Double {
        let date = Date(timeIntervalSinceNow: timeIntervalSinceNow)
        let calendar = Calendar(identifier: .gregorian)
        guard let midnight = DateComponents(
            calendar: calendar,
            timeZone: TimeZone.current,
            era: nil,
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date),
            day: calendar.component(.day, from: date),
            hour: 0,
            minute: 0,
            second: 0,
            nanosecond: calendar.component(.nanosecond, from: date)
        ).date else {
            return 0
        }
        return date.timeIntervalSince(midnight)
    }
    
    private func randomTime() -> Double {
        return Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max) * 86400
    }
}
