//
//  AnalogClockLayer.swift
//  FrontRowTunes
//
//  Created by Alexander Decker on 9/04/22.
//

import Foundation
import Cocoa

fileprivate let animationDuration: TimeInterval = 1


class AnalogClockLayer: CALayer {
    @objc static let radius: CGFloat = 200
    
    @objc var darkMode: Bool {
        didSet {
            updateClockFaceColour()
            updateClockHandColours()
        }
    }
    
    @objc var showSeconds: Bool = true {
        didSet {
            secondHand.isHidden = !showSeconds
            secondHingeOuter.isHidden = !showSeconds
        }
    }
    
    var startRequested: Bool = false
    @objc var isRunning: Bool = false
    var needsSync = false
    
    @objc init(darkMode: Bool) {
        self.darkMode = darkMode
        super.init()
        
        self.bounds = CGRect(x: 0, y: 0, width: 2*Self.radius, height: 2*Self.radius)
        
        setUpClockFace()
        setUpClockHands()
    }
    
    @objc override init(layer: Any) {
        let clockLayer = layer as? AnalogClockLayer
        self.darkMode = clockLayer?.darkMode ?? true
        self.showSeconds = clockLayer?.showSeconds ?? true
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc var tintColor: NSColor? {
        didSet {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.5)
            secondHand.backgroundColor = tintColor?.cgColor
            secondHingeOuter.backgroundColor = tintColor?.cgColor
            CATransaction.commit()
        }
    }
    
    // MARK: -
    
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
            let width = min(height / 2, Self.radius * 0.05)
            setUpFaceTick(
                width: width,
                height: height,
                rotation: CGFloat(minute)
            )
        }
        updateClockFaceColour()
    }
    
    private var tickLayers = [CALayer]()
    
    private func setUpFaceTick(width: CGFloat, height: CGFloat, rotation: CGFloat) {
        let tickLayer = CALayer()
        tickLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        tickLayer.cornerRadius = width / 2
        
        tickLayer.anchorPoint = CGPoint(x: 0.5, y: -(Self.radius - height + width/4) / height)
        tickLayer.position = CGPoint(x: Self.radius, y: Self.radius)
        tickLayer.transform = CATransform3DMakeRotation(-rotation / 60 * 2 * .pi, 0, 0, 1)
        
        self.addSublayer(tickLayer)
        self.tickLayers.append(tickLayer)
    }
    
    private func updateClockFaceColour() {
        let foregroundColor = darkMode ? CGColor.white : CGColor.black
        for tickLayer in tickLayers {
            tickLayer.backgroundColor = foregroundColor
        }
    }
    
    private let secondHand = CALayer()
    private let minuteHand = CALayer()
    private let hourHand = CALayer()
    
    private let secondHingeBackground = CALayer()
    private let secondHingeOuter = CALayer()
    private let secondHingeInner = CALayer()
    
    private func setUpClockHands() {
        let radius = Self.radius
        
        let handWidth: CGFloat = Self.radius * 0.07
        let handCornerRadius = handWidth / 2
        
        let hourHeight = radius * 0.55
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
        
        self.addSublayer(secondHingeBackground)
        
        let secondHandOverhang = 1.15
        secondHand.bounds = CGRect(x: 0, y: 0, width: 2, height: Self.radius * secondHandOverhang)
        secondHand.anchorPoint = CGPoint(x: 0.5, y: 1 - 1 / secondHandOverhang)
        self.addSublayer(secondHand)
        secondHand.position = CGPoint(x: radius, y: radius)
        
        let hingeBackgroundDiameter = radius * 0.09
        let hingeDiameter = hingeBackgroundDiameter * 5/6
        let innerHingeDiameter = hingeDiameter * 0.4
        secondHingeBackground.bounds = CGRect(x: 0, y: 0, width: hingeBackgroundDiameter, height: hingeBackgroundDiameter)
        secondHingeOuter.bounds = CGRect(x: 0, y: 0, width: hingeDiameter, height: hingeDiameter)
        secondHingeInner.bounds = CGRect(x: 0, y: 0, width: innerHingeDiameter, height: innerHingeDiameter)
        secondHingeBackground.cornerRadius = hingeBackgroundDiameter / 2
        secondHingeOuter.cornerRadius = hingeDiameter / 2
        secondHingeInner.cornerRadius = innerHingeDiameter / 2
        self.addSublayer(secondHingeOuter)
        self.addSublayer(secondHingeInner)
        secondHingeBackground.position = CGPoint(x: radius, y: radius)
        secondHingeOuter.position = CGPoint(x: radius, y: radius)
        secondHingeInner.position = CGPoint(x: radius, y: radius)
        
        updateClockHandColours()
    }
    
    private func updateClockHandColours() {
        let backgroundColor = darkMode ? CGColor.black : CGColor.white
        let foregroundColor = darkMode ? CGColor.white : CGColor.black
        hourHand.backgroundColor = foregroundColor
        minuteHand.backgroundColor = foregroundColor
        secondHingeBackground.backgroundColor = foregroundColor
        secondHingeInner.backgroundColor = backgroundColor
    }
    
    // MARK: - Animations
    
    @objc func setHandsToCurrentTime() {
        removeAllAnimations()
        setTime(getTime(timeIntervalSinceNow: 0), animationDuration: 0)
    }
    
    @objc func start() {
        if isRunning {
            return
        }
        
        // Animation only makes sense if the layer is attached to a window and has a presentation layer.
        // If presentation() is nil, any animated setTime will just snap to the end state.
        guard secondHand.presentation() != nil else {
            // Retry
            NSLog("request start")
            self.startRequested = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self = self, self.startRequested else { return }
                self.start()
            }
            return
        }
        
        isRunning = true
        startRequested = false
        setHandsToCurrentTime()
        needsSync = true
        setUpAnimationsIfNeeded()
    }
    
    @objc func stop() {
        isRunning = false
        startRequested = false
        animationTimer?.invalidate()
        animationTimer = nil
        removeAllAnimations()
    }
    
    var animationTimer: Timer?
    
    func setUpAnimationsIfNeeded() {
        guard animationTimer == nil else {
            return
        }
        
        let timer = Timer(timeInterval: animationDuration, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.setTime(self.getTime(timeIntervalSinceNow: animationDuration), animationDuration: animationDuration)
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        animationTimer = timer
    }
    
    private func getHourMinuteSecond(_ time: Double) -> (Double, Double, Double) {
        var hour = time / 3600
        if hour > 12 { hour -= 12 }
        let minute = (time / 60).truncatingRemainder(dividingBy: 60)
        let second = time.truncatingRemainder(dividingBy: 60)
        return (hour, minute, second)
    }
    
    private func setTime(_ time: Double, animationDuration: TimeInterval) {
        let (hour, minute, second) = getHourMinuteSecond(time)
        
        let hourTransform = CATransform3DMakeRotation(-hour * 2 * CGFloat.pi / 12, 0, 0, 1)
        let minuteTransform = CATransform3DMakeRotation(-minute * 2 * CGFloat.pi / 60, 0, 0, 1)
        let secondTransform = CATransform3DMakeRotation(-second * 2 * CGFloat.pi / 60, 0, 0, 1)
        
        if animationDuration > 0 {
            guard isRunning && (secondHand.presentation() != nil) else { return }
            
            animateHand(hourHand, to: hourTransform, duration: animationDuration)
            animateHand(minuteHand, to: minuteTransform, duration: animationDuration)
            animateHand(secondHand, to: secondTransform, duration: animationDuration)
            needsSync = false
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            hourHand.transform = hourTransform
            minuteHand.transform = minuteTransform
            secondHand.transform = secondTransform
            CATransaction.commit()
        }
    }
    
    private func animateHand(_ hand: CALayer, to targetTransform: CATransform3D, duration: TimeInterval) {
        var currentTransform: CATransform3D
        if (needsSync) {
            // always start from model transform
            currentTransform = hand.transform
        } else {
            // prefer presentation transform
            currentTransform = hand.presentation()?.transform ?? hand.transform
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        hand.removeAnimation(forKey: "rotation")
        hand.transform = currentTransform
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(caTransform3D: currentTransform)
        animation.toValue = NSValue(caTransform3D: targetTransform)
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .removed
        animation.isRemovedOnCompletion = true
        
        hand.add(animation, forKey: "rotation")
        hand.transform = targetTransform
        
        CATransaction.commit()
    }
    
    private func getTime(timeIntervalSinceNow: TimeInterval) -> Double {
        let date = Date(timeIntervalSinceNow: timeIntervalSinceNow)
        let midnight = Calendar.current.startOfDay(for: date)
        return date.timeIntervalSince(midnight)
    }
    
    private func randomTime() -> Double {
        return Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max) * 86400
    }
}
