//
//  GradientView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/1/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct GradientView: View, Equatable {
    static func == (lhs: GradientView, rhs: GradientView) -> Bool {
        lhs.currentPrayer == rhs.currentPrayer && lhs.appearance.id == rhs.appearance.id
    }
    
    @Binding var currentPrayer: Prayer
    @State var lastShownPrayer: Prayer? = nil
    @Binding var appearance: AppearanceSettings
    @State private var firstPlane: Bool = true
    
    @State private var gradientA: [Color] = {
        let settings = AthanManager.shared.appearanceSettings
        let startColors = settings.colors(for: settings.isDynamic ? AthanManager.shared.currentPrayer : nil)
        return [startColors.0, startColors.1]
    }()
    
    @State private var gradientB: [Color] = { // setting here is useless
        let settings = AthanManager.shared.appearanceSettings
        let startColors = settings.colors(for: settings.isDynamic ? AthanManager.shared.currentPrayer : nil)
        return [startColors.0, startColors.1]
    }()
    
    @State var lastTimerDate = Date(timeIntervalSinceNow: -100)
    
    func adjustGradient(gradient: [Color]) {
        gradientA = gradient
        gradientB = gradient
    }
    
    func setGradient(gradient: [Color]) {
        if firstPlane {
            gradientB = gradient
        } else {
            gradientA = gradient
        }
        firstPlane = !firstPlane
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: gradientA), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            LinearGradient(gradient: Gradient(colors: gradientB), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .opacity(firstPlane ? 0 : 1)
                .onValueChanged(currentPrayer) { x in
                    print("CP CHANGE: ", currentPrayer)
                    // start a 0.1 second timer that updates the view
                    // to avoid state change issues
//                    print("GRADIENT PRAYER CHANGED")
                    
                    // if last fire of timer happened sufficiently long ago,
                    // we know that the state change is being caused by a change in currentPrayer
//                    if abs(lastTimerDate.timeIntervalSinceNow) > 0.02 {
                    if currentPrayer != lastShownPrayer {
                        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { t in
                            
                            if abs(lastTimerDate.timeIntervalSinceNow) > 0.012 {
                            lastTimerDate = Date()
//                            print("GRADIENT TIMER CALLED")
                            lastShownPrayer = currentPrayer
                            let startColors = appearance.colors(for: appearance.isDynamic ? currentPrayer : nil)
                            withAnimation {
                                setGradient(gradient: [startColors.0, startColors.1])
                            }
                            }
                        })
                    }
                }
                .onValueChanged(appearance) { app in
                    print("AP CHANGE: ", appearance.id, appearance.isDynamic)
                    if abs(lastTimerDate.timeIntervalSinceNow) > 0.012 {
                        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false, block: { t in
                            
                            // check again in case something else tried to mess
                            if abs(lastTimerDate.timeIntervalSinceNow) > 0.012 {
                                lastTimerDate = Date()
        //                            print("GRADIENT TIMER CALLED")
                                lastShownPrayer = currentPrayer
                                let startColors = appearance.colors(for: appearance.isDynamic ? currentPrayer : nil)
                                withAnimation {
                                    setGradient(gradient: [startColors.0, startColors.1])
                                }
                            }
                        })
                    }

                }
        }
        
        //                                                    let settings = AthanManager.shared.appearanceSettings
        //                                                    let startColors = settings.colors(for: settings.isDynamic ? manager.currentPrayer : nil)
        //
        //                                                    if let lastShown = lastShownPrayer {
        //                                                        setGradient(gradient: [startColors.0, startColors.1])
        //                                                    } else {
        //                                                        adjustGradient(gradient: [startColors.0, startColors.1])
        //                                                    }
        //                                                    lastShownPrayer = manager.currentPrayer
        
    }
}
