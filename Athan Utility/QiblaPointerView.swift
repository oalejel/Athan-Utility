//
//  QiblaPointerView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/14/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

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
    var angle: Double = 90
    var qiblaAngle: Double = 0 // correct angle, which we should highlight and vibrate for
//    private let pointerLength: CGFloat = 60
    // make pointerlength equal frame over
    
    var body: some View {
        GeometryReader { g in
            let pointerLength = g.size.width / 6
            let lineWidth = (g.size.width - pointerLength) / 13
            
            ZStack {
                Image("kaba_2")
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
                    .rotationEffect(.degrees(angle), anchor: .center)
                    .animation(Animation.default.speed(1))
                
            }
        }
    
    }
}

@available(iOS 13.0.0, *)
struct QiblaPointerPreview: PreviewProvider {
    static var previews: some View {
        QiblaPointerView()
            .background(Rectangle(), alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
