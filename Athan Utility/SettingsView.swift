//
//  SettingsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/28/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan
import StoreKit


enum SettingsSectionType {
    case General, Sounds, Prayer(Prayer), CalculationMethod, CustomNames, Colors, FajrAlarm
}

@available(iOS 13.0.0, *)
struct SettingsView: View {
    @EnvironmentObject var manager: ObservableAthanManager
    
    // settings state held at top level, saved to athan manager by general view
    @State var tempLocationSettings: LocationSettings = AthanManager.shared.locationSettings.copy() as! LocationSettings
    @State var tempNotificationSettings = AthanManager.shared.notificationSettings.copy() as! NotificationSettings
    @State var tempPrayerSettings = AthanManager.shared.prayerSettings.copy() as! PrayerSettings
    @State var tempAppearanceSettings = AthanManager.shared.appearanceSettings.copy() as! AppearanceSettings
    
    @Binding var parentSession: PresentedSectionType // used to trigger transition back
    
    @State var activeSection = SettingsSectionType.General
    @State var dismissSounds = false
    // Live x-offset of the detail pane during an interactive edge-swipe back.
    @State private var backDrag: CGFloat = 0
    
    let calculationMethods = CalculationMethod.usefulCases()
    let madhabs = Madhab.allCases
    @State var savedOffset = CGFloat(0)

    init(parentSession: Binding<PresentedSectionType>, initialSection: SettingsSectionType = .General) {
        self._parentSession = parentSession
        self._activeSection = State(initialValue: initialSection)
    }

    var body: some View {
        GeometryReader { g in
            switch activeSection {
            case .General:
                ScrollViewReader { proxy in
                    GeneralSettingView(tempLocationSettings: $tempLocationSettings, tempNotificationSettings: $tempNotificationSettings, tempPrayerSettings: $tempPrayerSettings, tempAppearanceSettings: $tempAppearanceSettings, parentSession: $parentSession, activeSettingsSection: $activeSection, dismissSounds: $dismissSounds, settingsState: activeSection,
                                       savedOffset: $savedOffset, proxy: proxy)
                }
            case .Sounds:
                SoundSettingView(tempNotificationSettings: $tempNotificationSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                    .interactiveBack(offset: $backDrag, width: g.size.width) { activeSection = .General }
            case .Prayer(let p):
                #warning("change binding")
                PrayerSettingsView(noteSettings: $tempNotificationSettings, prayer: p, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                    .interactiveBack(offset: $backDrag, width: g.size.width) { activeSection = .General }
            case .Colors:
                ColorsView(tempAppearanceSettings: $tempAppearanceSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                    .interactiveBack(offset: $backDrag, width: g.size.width) { activeSection = .General }
            case .CustomNames:
                NameOverridesView(tempPrayerSettings: $tempPrayerSettings, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                    .interactiveBack(offset: $backDrag, width: g.size.width) { activeSection = .General }
            case .CalculationMethod:
                CalculationMethodView(tempPrayerSettings: $tempPrayerSettings, viewSelectedMethod: tempPrayerSettings.calculationMethod, activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                    .interactiveBack(offset: $backDrag, width: g.size.width) { activeSection = .General }
            case .FajrAlarm:
                FajrAlarmSettingsView(activeSection: $activeSection)
                    .transition(.move(edge: .trailing))
                    .interactiveBack(offset: $backDrag, width: g.size.width) { activeSection = .General }
            }
        }
    }

}

// Native-feeling INTERACTIVE back: a swipe that starts at the left screen edge
// drives the pane's position 1:1 with the finger (like UINavigationController's
// interactive pop), then either completes the pop or snaps back on release —
// without wrapping everything in a UINavigationController (which broke the
// custom layout).
@available(iOS 13.0.0, *)
private extension View {
    func interactiveBack(offset: Binding<CGFloat>, width: CGFloat, onComplete: @escaping () -> Void) -> some View {
        modifier(InteractiveBackModifier(offset: offset, width: width, onComplete: onComplete))
    }
}

@available(iOS 13.0.0, *)
private struct InteractiveBackModifier: ViewModifier {
    @Binding var offset: CGFloat
    let width: CGFloat
    let onComplete: () -> Void

    func body(content: Content) -> some View {
        content
            // Follows the finger during the drag; animates to rest on release.
            .offset(x: max(0, offset))
            // `.simultaneousGesture` so vertical scrolling / sliders inside the
            // pane keep working — a vertical drag has ~0 horizontal translation
            // and leaves the offset at 0.
            .simultaneousGesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .global)
                    .onChanged { v in
                        guard v.startLocation.x < 30 else { return }   // edge-anchored only
                        offset = max(0, v.translation.width)           // track the finger
                    }
                    .onEnded { v in
                        guard v.startLocation.x < 30 else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { offset = 0 }
                            return
                        }
                        // Complete if dragged past a third of the width, or flung.
                        let past = v.translation.width > width * 0.33
                        let flung = v.predictedEndTranslation.width > width * 0.5
                        if past || flung {
                            // Slide the pane fully off to the right...
                            withAnimation(.easeOut(duration: 0.2)) { offset = width }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
                                // ...then swap panes with animations DISABLED so the
                                // pane's move-transition doesn't re-animate (that was
                                // the flicker). Clear the drag offset only on the next
                                // tick, once the pane is already gone, so it never
                                // snaps back to 0 for a frame.
                                var tx = Transaction()
                                tx.disablesAnimations = true
                                withTransaction(tx) { onComplete() }
                                DispatchQueue.main.async { offset = 0 }
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { offset = 0 }
                        }
                    }
            )
    }
}

#Preview {
    ZStack {
        LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
        SettingsView(parentSession: .constant(.Settings))
    }
    .environmentObject(ObservableAthanManager.shared)
}
