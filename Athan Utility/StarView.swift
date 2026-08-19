//
//  StarView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/14/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI

struct StarState {
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    let color: Color
    
    
    init() {
        radius = 1.0 + CGFloat((arc4random() % 100)) / 50
        x = CGFloat.random(in: 0..<1)
        y = CGFloat.random(in: 0..<1)
        opacity = Double.random(in: 0.5..<0.8)
        let randomColorIndex = Int.random(in: 0..<4)
        switch randomColorIndex {
        case 0: color = .white
        case 1: color = Color(red: 0.9, green: 0.8, blue: 0.8)
        case 2: color = Color(red: 0.9, green: 0.7, blue: 0.9)
        case 3: color = Color(red: 0.9, green: 0.8, blue: 1)
        default: color = Color(red: 0.7, green: 0.9, blue: 1)
        }
    }
}

struct StarView: View, Equatable {
    static func == (lhs: StarView, rhs: StarView) -> Bool {
        lhs.fadingIndices == rhs.fadingIndices
    }
    
    @State var starCount: Int = 100
    @State var fadingIndices = 0
    static var startStates: [StarState] = []

    private var isMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }
    
    init(starCount sc: Int) {
        starCount = sc
        if StarView.startStates.count < starCount {
            for _ in 0..<starCount {
                StarView.startStates.append(StarState())
            }
        }
    }
    
    var body: some View {
        GeometryReader { g in
            // Absolute-positioned stars fill the entire area (0…1 of width/height), so the
            // field always covers the whole detail view regardless of pane size.
            let starField = ZStack(alignment: .topLeading) {
                Color.clear
                ForEach(0..<starCount, id: \.self) { idx in
                    let ss = StarView.startStates[idx]
                    Circle()
                        .frame(width: ss.radius, height: ss.radius)
                        .foregroundColor(ss.color)
                        .opacity((idx < fadingIndices && idx % 3 == 0) ? ss.opacity : 0.5)
                        .position(x: ss.x * g.size.width, y: ss.y * g.size.height)
                        .onAppear {
                            if isMac { fadingIndices = starCount }          // static on Mac
                            else { withAnimation { fadingIndices = starCount } }
                        }
                        // No twinkle on Mac — the user wants the isha stars to stay still.
                        .animation(isMac ? nil : Animation.easeInOut(duration: 2).repeatForever(autoreverses: true))
                }
            }
            .frame(width: g.size.width, height: g.size.height)

            Group {
                #if targetEnvironment(macCatalyst)
                starField                       // no gyro on Mac; parallax would just jitter on resize
                #else
                starField.parallax(amount: 20)
                #endif
            }
            .frame(width: g.size.width, height: g.size.height)
            .mask(
                LinearGradient(gradient: Gradient(colors: [.white, .white, .clear]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .frame(width: g.size.width, height: g.size.height)
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}


struct StarView_Previews: PreviewProvider {
    static var previews: some View {
        StarView(starCount: 100)
            .background(Color.black)
            .previewDevice("iPhone Xs")
        
    }
}
