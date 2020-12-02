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
    @State var amplitude: CGFloat = 50
    @State var verticalOffset: CGFloat = 0

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
            let y = (cos(CGFloat(i) * 2 * CGFloat.pi / CGFloat(steps)) * amplitude) + verticalOffset + rect.midY
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
    var progress: CGFloat = 0
    var sunlightFraction: CGFloat = 0.5 // % of 24 hours that has sunlight
    
    @State var isDragging = false
    @State var manualProgress: CGFloat = 0
    @State var hidingCircle = false
    @State var dhuhrTime: Date
    
    let df: DateFormatter = {
       let d = DateFormatter()
        d.dateFormat = "hh:mm a"
        return d
    }()
    
    var body: some View {
        GeometryReader  { g in
            let amplitude: CGFloat = g.size.height / 4
//            let verticalOffset: CGFloat = amplitude - 2 * amplitude * sunlightFraction
//            let verticalOffset: CGFloat = amplitude - 2 * amplitude * cos(sunlightFraction * CGFloat.pi / 2)
            let theta = CGFloat.pi - 2 * CGFloat.pi * CGFloat(AthanManager.shared.todayTimes.dhuhr.timeIntervalSince(AthanManager.shared.todayTimes.sunrise) / 86400.0)
            let verticalOffset: CGFloat = -1 * amplitude * cos(theta)
//            let sunY: CGFloat = cos((isDragging ? manualProgress : progress) * 2 * CGFloat.pi) * amplitude + verticalOffset
        
            VStack {
//                Spacer()
                ZStack {
                    HStack {
                        Spacer()
                        VStack {
                            let time = dhuhrTime.addingTimeInterval(86400 * (Double(manualProgress) - 0.5))
                            Text(df.string(from: time))
//                                .font(Font.body.weight(.semibold))
                                .font(.system(size: 12, design: .monospaced))
                                .bold()
                                .foregroundColor(Color(.lightText))
                                .padding([.top, .bottom], 6)
                                .padding([.leading, .trailing], 8)
                                .background(
                                    Rectangle()
//                                        .foregroundColor(.init(.sRGB, white: 1, opacity: 0.2))
//                                        .foregroundColor(Color(.lightText))
                                        .addBorder(Color(.lightText), width: 2, cornerRadius: 8)
//                                        .cornerRadius(4)
                                        .foregroundColor(.clear)
//                                        .border(Color(.lightText))
                                )
                                .padding()
                            Spacer()
                        }
                    }
                    .opacity(isDragging ? 1 : 0)
                    .animation(.linear(duration: 0.3))
                    
                    Rectangle()
                        .foregroundColor(.init(.sRGB, white: 1, opacity: 0.00000000001)) // hack to avoid full transparency and allow input
                        .gesture(
                            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                                .onChanged({ value in
                                    withAnimation(.linear(duration: 0.3)) {
                                        isDragging = true
                                        manualProgress = value.location.x / g.size.width
                                    }
                                })
                                .onEnded({ value in
                                    print("let go")
                                    withAnimation(.linear(duration: 0.1)) {
                                        isDragging = false
//                                        manualProgress = progress // TODO: get animation to travel path accurately
                                    }
                                })
                        )

                    Rectangle()
                        .frame(width: g.size.width, height: 1)
                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        
                    Rectangle()
                        .frame(width: 1,
                               height: abs(cos(manualProgress * 2 * CGFloat.pi) * amplitude + verticalOffset),
                               alignment: .center)
                        .offset(x: manualProgress * g.size.width - 0.5 * g.size.width,
                                y: 0.5 * (cos(manualProgress * 2 * CGFloat.pi) * amplitude + verticalOffset))
                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        .opacity(isDragging ? 1 : 0)
                        .animation(.linear(duration: 0.3))
                    
                    SineLine(amplitude: amplitude, verticalOffset: verticalOffset)
                        .stroke(style: StrokeStyle(lineWidth: 2,
                                                   lineCap: .round,
                                                   lineJoin: .round,
                                                   miterLimit: 4,
                                                   dash: [6, 5],
                                                   dashPhase: 0))
                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))

                    Circle()
                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        .frame(width: g.size.width / 30, height: g.size.width / 30)
                        .offset(x: (isDragging ? manualProgress : progress) * g.size.width - 0.5 * g.size.width,
                                y: cos((isDragging ? manualProgress : progress) * 2 * CGFloat.pi) * amplitude + verticalOffset)
//                        .animation(.linear(duration: 0.3))
                }
//                Spacer()
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct SolarViewPreview: PreviewProvider {
    static var previews: some View {
//        let timeDiff = 10.1 // hours
        
        SolarView(progress: 0.3, sunlightFraction: 0.6, dhuhrTime: Date())
            .background(Rectangle()
                            .foregroundColor(.blue), alignment: .center)
            .frame(width: 380, height: 200, alignment: .center)
    }
}
