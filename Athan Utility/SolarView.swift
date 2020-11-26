//
//  SolarView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/25/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

@available(iOS 13.0.0, *)
struct SineLine: Shape {
    @State var amplitude: Double = 50
    @State var verticalOffset: Double = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 360
        let stepX = rect.width / CGFloat(steps)
        
//        path.move(to: CGPoint(x: 0, y: rect.midY))
        // Draw a line up to the vertical center
//        path.addLine(to: CGPoint(x: 0, y: rect.midY))
        // Loop and draw steps in straingt line segments
        for i in 0...steps {
            
            let x = CGFloat(i) * stepX
            let y = (cos(Double(i) * 2 * Double.pi / Double(steps)) * amplitude) + verticalOffset + Double(rect.midY)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: CGFloat(y)))
            }
            
            path.addLine(to: CGPoint(x: x, y: CGFloat(y)))
        }

        return path
    }
}


// TODO: have peak always be around the same y pos, and just adjust amplitude
// of graph instead
@available(iOS 13.0.0, *)
struct SolarView: View {
    @State var progress: Double = 0
    @State var sunlightFraction: Double = 0.5 // % of 24 hours that has sunlight
    
    var body: some View {
        GeometryReader  { g in
            let amplitude = Double(g.size.height / 4)
            let verticalOffset: Double = amplitude - 2 * amplitude * sunlightFraction
            let sunY: Double = cos(progress * 2 * Double.pi) * amplitude + verticalOffset
            
            VStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .frame(width: g.size.width, height: 1)
                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                    SineLine(amplitude: amplitude, verticalOffset: verticalOffset)
                        .stroke(style: StrokeStyle(lineWidth: 2,
                                                   lineCap: .round,
                                                   lineJoin: .round,
                                                   miterLimit: 4,
                                                   dash: [6, 5],
                                                   dashPhase: 0))
                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
//                    Blur()

//                        .mask(
//                        )
                    Circle()
                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        .frame(width: g.size.width / 30, height: g.size.width / 30)
                        .offset(x: -0.5 * g.size.width + CGFloat(progress) * g.size.width,
                                y: CGFloat(sunY))
                        .onAppear { progress = 0.25 }

                }
                Spacer()
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct SolarViewPreview: PreviewProvider {
    static var previews: some View {
//        let timeDiff = 10.1 // hours
        
        SolarView(progress: 0.3, sunlightFraction: 0.6)
            .background(Rectangle()
                            .foregroundColor(.blue), alignment: .center)
            .frame(width: 380, height: 200, alignment: .center)
    }
}
