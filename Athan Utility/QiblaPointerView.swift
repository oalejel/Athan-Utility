//
//  QiblaPointerView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/14/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 13.0.0, *)
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

@available(iOS 13.0.0, *)
struct QiblaPointerView: View {
    @Binding var angle: Double
    @Binding var qiblaAngle: Double // correct angle, which we should highlight and vibrate for
    
    // Haptic gating state
    @State private var isWithinHitWindow = false
    @State private var lastHapticDate: Date? = nil
    
    // Tunables
    private let hitWindowDegrees: Double = 3.0       // tight window to trigger
    private let exitWindowDegrees: Double = 6.0      // hysteresis exit threshold
    private let cooldownSeconds: TimeInterval = 1.0  // debounce
    
    var body: some View {
        GeometryReader { g in
            let pointerLength = g.size.width / 6
            let lineWidth = (g.size.width - pointerLength) / 13
            
            ZStack {
                Image("kaba")
                    .resizable()
                    .scaledToFit()
                    .frame(width: (g.size.width - pointerLength * 2) / 2.2,
                           height:  (g.size.width - pointerLength * 2) / 2.2,
                           alignment: .center)
                Circle()
                    .strokeBorder(Color.white, lineWidth: lineWidth)
                    .padding(pointerLength)
                
                Triangle()
                    .frame(width: pointerLength * 1.2, height: pointerLength, alignment: .center)
                    .offset(x: 0, y: (g.size.width / -2) - lineWidth + pointerLength)
                    .foregroundColor(.white)
                    .shortRotationEffect(.degrees(pointerVisualAngleDegrees), id: 1)
                    // Scope the animation to heading changes only — a valueless
                    // .animation() also animates the size-driven offset, which makes
                    // the tip lag behind the circle while resizing the macOS window.
                    .animation(.default, value: pointerVisualAngleDegrees)
                    .transition(.opacity)
            }
            // Accessibility: describe what this is, current alignment, and the haptic behavior
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(Strings.qiblaCompassLabel ?? "Qibla compass"))
            .accessibilityValue(Text(accessibilityAlignmentString))
            .accessibilityHint(Text(Strings.qiblaCompassHint ?? "Vibrates when aligned within three degrees"))
            .accessibilityAddTraits(.updatesFrequently)
            // Monitor heading/qibla changes to trigger haptics
            .onChange(of: angle) { _ in
                evaluateHaptic()
                announceIfNeededForAccessibility()
            }
            .onChange(of: qiblaAngle) { _ in
                evaluateHaptic()
                announceIfNeededForAccessibility()
            }
            .onAppear {
                // Initialize state based on current values
                evaluateHaptic(initial: true)
            }
        }
    }
    
    // Computed: the visual rotation applied to the pointer (triangle), in degrees.
    // This matches the rotation used in the view so our difference math aligns with what the user sees.
    private var pointerVisualAngleDegrees: Double {
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        // In your view, you rotate by (RTL ? angle - qiblaAngle : qiblaAngle - angle)
        return isRTL ? (angle - qiblaAngle) : (qiblaAngle - angle)
    }
    
    // Signed difference in [-180, 180]
    private var signedDiffToUp: Double {
        normalizeToSigned180(pointerVisualAngleDegrees)
    }
    
    // Smallest absolute angular difference to "straight up" (0 degrees)
    private var absoluteDiffToUp: Double {
        abs(signedDiffToUp)
    }
    
    // Accessibility-friendly textual description of alignment
    private var accessibilityAlignmentString: String {
        // Round to nearest whole degree for speech clarity
        let rounded = Int(abs(absoluteDiffToUp).rounded())
        if absoluteDiffToUp <= hitWindowDegrees {
            return Strings.qiblaAlignedValue ?? "Aligned with Qibla"
        } else {
            // Indicate left/right to help users rotate the right way.
            let direction = signedDiffToUp > 0 ? (Strings.qiblaTurnRight ?? "Turn right") : (Strings.qiblaTurnLeft ?? "Turn left")
            // Example: "5 degrees. Turn right."
            return "\(rounded) \(Strings.degreesAbbrev ?? "degrees"). \(direction)."
        }
    }
    
    private func normalizeToSigned180(_ deg: Double) -> Double {
        var x = fmod(deg + 180.0, 360.0)
        if x < 0 { x += 360.0 }
        return x - 180.0
    }
    
    private func evaluateHaptic(initial: Bool = false) {
        let diff = absoluteDiffToUp
        
        // Hysteresis logic
        if isWithinHitWindow {
            // Wait until user leaves the wider exit window before re-arming
            if diff > exitWindowDegrees {
                isWithinHitWindow = false
            }
            return
        } else {
            // Only trigger when entering the tight hit window
            if diff <= hitWindowDegrees {
                // Debounce with cooldown
                let now = Date()
                if let last = lastHapticDate, now.timeIntervalSince(last) < cooldownSeconds {
                    // Still cooling down
                    isWithinHitWindow = true // mark as within window to avoid spamming while staying in range
                    return
                }
                
                // Fire haptic
                triggerHaptic()
                lastHapticDate = now
                isWithinHitWindow = true
            }
        }
    }
    
    private func triggerHaptic() {
        // iOS haptic
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        
        // If you decide to support watchOS haptics here in the future:
        // #if os(watchOS)
        // WKInterfaceDevice.current().play(.success)
        // #endif
    }
    
    // Optional: politely announce alignment changes for VoiceOver users when they get aligned,
    // without being too chatty. This posts a layout change announcement only on "hit".
    private func announceIfNeededForAccessibility() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        if isWithinHitWindow {
            UIAccessibility.post(notification: .announcement, argument: accessibilityAlignmentString)
        }
    }
}


infix operator %% : DefaultPrecedence
extension Double {
    static  func %% (_ left: Double, _ right: Double) -> Double {
        let truncatingRemainder = left.truncatingRemainder(dividingBy: right)
        return truncatingRemainder >= 0 ? truncatingRemainder : truncatingRemainder+abs(right)
    }
}

@available(iOS 13.0.0, *)
extension View {
    func shortRotationEffect(_ angle: Angle,anchor: UnitPoint = .center, id:Int) -> some View {
        modifier(ShortRotation(angle: angle,anchor:anchor, id:id))
    }
}

@available(iOS 13.0.0, *)
struct ShortRotation: ViewModifier {
    static var storage:[Int:Angle] = [:]
    
    var angle:Angle
    var anchor:UnitPoint
    var id:Int
    
    func getAngle() -> Angle {
        var newAngle = angle
        
        if let lastAngle = ShortRotation.storage[id] {
            let change:Double = (newAngle.degrees - lastAngle.degrees) %% 360.0
            
            if change < 180 {
                newAngle = lastAngle + Angle.init(degrees: change)
            }
            else {
                newAngle = lastAngle + Angle.init(degrees: change - 360)
            }
        }
        
        ShortRotation.storage[id] = newAngle
        
        return newAngle
    }
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(getAngle(),anchor: anchor)
    }
}

@available(iOS 13.0.0, *)
struct QiblaPointerPreview: PreviewProvider {
    static var previews: some View {
        QiblaPointerView(angle: .constant(10), qiblaAngle: .constant(13))
            .background(Rectangle(), alignment: .center)
    }
}
