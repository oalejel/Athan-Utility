//
//  StarView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/14/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
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

@available(iOS 13.0.0, *)
struct StarView: View, Equatable {
    static func == (lhs: StarView, rhs: StarView) -> Bool {
        lhs.fadingIndices == rhs.fadingIndices
//        true
    }
    
    @State var starCount: Int = 100
    @State var fadingIndices = 0
    static var startStates: [StarState] = []
    
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
            ZStack {
                ForEach(0..<starCount) { idx in
                    let ss = StarView.startStates[idx]
                    let randomRadius = ss.radius
                    let randomX = ss.x * g.size.width
                    let randomY = ss.y * g.size.height
                    let randomOpacity = ss.opacity
                    Circle()
                        .clipped(antialiased: true)
                        //                        .shadow(color: Color.white, radius: 0.1)
                        .frame(width: randomRadius, height: randomRadius)
                        .offset(x: randomX, y: randomY)
                        .foregroundColor(ss.color)
                        .opacity((idx < fadingIndices && idx % 3 == 0) ? randomOpacity : 0.5)
                        .onAppear {
                            withAnimation {
                                fadingIndices = starCount
                            }
                        }
                        .animation(Animation.easeInOut(duration:2).repeatForever(autoreverses:true))
                }
            }

            .parallax(amount: 20)
            .offset(x: g.size.width / -2, y: g.size.height / -2)
            .mask(
                LinearGradient(gradient: Gradient(colors: [.white, .white, .clear]),
                               startPoint: .top,
                               endPoint: .bottom)
//                    .position(x: 0, y: 0)
                    .frame(width: g.size.width, height: g.size.height)
//                    .offset(x: g.size.width / 2, y: g.size.height / 2)
            )
        }
    }
}


@available(iOS 13.0.0, *)
struct StarView_Previews: PreviewProvider {
    static var previews: some View {
        StarView(starCount: 100)
            .background(Color.black)
            .previewDevice("iPhone Xs")
        
    }
}
