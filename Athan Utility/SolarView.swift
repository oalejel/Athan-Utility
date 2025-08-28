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
struct SolarView: View, Equatable {
    static func == (lhs: SolarView, rhs: SolarView) -> Bool {
        return lhs.isDragging == rhs.isDragging && lhs.dayProgress == rhs.dayProgress && lhs.sunlightFraction == rhs.sunlightFraction && lhs.manualDayProgress == rhs.manualDayProgress
    }
    
    @Binding var dayProgress: CGFloat
    @Binding var manualDayProgress: CGFloat
    @Binding var isDragging: Bool

    @State var sunlightFraction: CGFloat = 0.5 // % of 24 hours that has sunlight
    
    @State var hidingCircle = false
    @State var dhuhrTime: Date
    @State var sunriseTime: Date
    
    let df: DateFormatter = {
       let d = DateFormatter()
        d.dateFormat = "hh:mm a"
        return d
    }()
    
    func colorForProgress() -> (Color, Color, CGFloat) {
        // 0->sunrise - 0.05
        // sunrise-0.05 -> sunrise + 0.05
        // sunrise + 0.05 -> maghrib - 0.05
        // maghrib - 0.05 -> isha
        // isha -> 1
        let sunrisePercent = 0.5 - CGFloat(dhuhrTime.timeIntervalSince(sunriseTime) / 86400.0)
        let sunsetPercent = 1 - sunrisePercent
        let yellow = Color(.sRGB, red: Double(255)/255, green: Double(242)/255, blue: Double(171)/255, opacity: 1)
        let orange = Color(.sRGB, red: Double(255)/255, green: Double(202)/255, blue: Double(171)/255, opacity: 1)
        
        let progressOfInterest = isDragging ? manualDayProgress : dayProgress
//        if progressOfInterest < 0 { progressOfInterest *= -1}
        switch progressOfInterest {
        case _ where progressOfInterest > sunsetPercent + 0.05:
            return (Color.clear, .white, 3)
        case _ where progressOfInterest > sunsetPercent - 0.05:
            return (Color.orange, orange, 7)
        case _ where progressOfInterest > sunrisePercent + 0.05:
            return (Color.white, yellow, 3)
        case _ where progressOfInterest > sunrisePercent - 0.05:
            return (Color.orange, orange, 7)
        case _ where progressOfInterest >= 0:
            return (Color.clear, .white, 3)
        default:
            print("sun progress out of bounds?")
            return (Color.clear, .white, 3)
        }
    }
    
    var body: some View {
        GeometryReader  { g in
            let amplitude: CGFloat = g.size.height / 2
//            let verticalOffset: CGFloat = amplitude - 2 * amplitude * sunlightFraction
//            let verticalOffset: CGFloat = amplitude - 2 * amplitude * cos(sunlightFraction * CGFloat.pi / 2)
            let theta = CGFloat.pi - 2 * CGFloat.pi * CGFloat(dhuhrTime.timeIntervalSince(sunriseTime) / 86400.0)
            let verticalOffset: CGFloat = -1 * amplitude * cos(theta)
//            let sunY: CGFloat = cos((isDragging ? manualProgress : progress) * 2 * CGFloat.pi) * amplitude + verticalOffset
        
            VStack {
//                Spacer()
                ZStack {
                    HStack {
                        Spacer()
                        VStack {
                            let time = dhuhrTime.addingTimeInterval(86400 * (Double(manualDayProgress) - 0.5))
                            Text(df.string(from: time))
//                                .font(Font.body.weight(.semibold))
                                .font(.system(size: 13, design: .monospaced))
                                .bold()
                                .foregroundColor(Color(.lightText))
                                .padding([.top, .bottom], 6)
                                .padding([.leading, .trailing], 8)
//                                .background(
//                                    Rectangle()
////                                        .foregroundColor(.init(.sRGB, white: 1, opacity: 0.2))
////                                        .foregroundColor(Color(.lightText))
//                                        .addBorder(Color(.lightText), width: 2, cornerRadius: 8)
////                                        .cornerRadius(4)
//                                        .foregroundColor(.clear)
////                                        .border(Color(.lightText))
//                                        .opacity(g.size.width < 600 ? 0 : 1)
//                                )
//                                .padding([.trailing])
//                                .padding([.trailing])
                                .offset(y: -30)
                            Spacer()
                        }
                        Spacer()
                    }
                    .opacity(isDragging ? 1 : 0)
                    .animation(.linear(duration: 0.3))
                    
                    Rectangle()
                        .foregroundColor(.init(.sRGB, white: 1, opacity: 0.00000000001)) // hack to avoid full transparency and allow input
                        .gesture(
                            DragGesture(minimumDistance: 2, coordinateSpace: .local)
                                .onChanged({ value in
                                    withAnimation(.linear(duration: 0.3)) {
                                        isDragging = true
                                        manualDayProgress = value.location.x / g.size.width
                                        if UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft {
                                            manualDayProgress = (g.size.width - value.location.x) / g.size.width
                                        } else {
                                            manualDayProgress = value.location.x / g.size.width
                                        }
                                    }
                                })
                                .onEnded({ value in
                                    print("let go")
                                    withAnimation(.linear(duration: 0.1)) {
                                        isDragging = false
//                                        manualDayProgress = progress // TODO: get animation to travel path accurately
                                    }
                                })
                        )

                    Rectangle() // horizontal line
                        .frame(width: g.size.width, height: 1)
                        .foregroundColor(Color(.lightText))
                        .offset(y: -1 * verticalOffset)
//                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        
                    Rectangle()
                        .frame(width: 1,
                               height: abs(cos(manualDayProgress * 2 * CGFloat.pi) * amplitude + verticalOffset),
                               alignment: .center)
                        .offset(x: manualDayProgress * g.size.width - 0.5 * g.size.width,
                                y: 0.5 * (cos(manualDayProgress * 2 * CGFloat.pi) * amplitude - verticalOffset))
                        .foregroundColor(Color(.lightText))
//                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        .opacity(isDragging ? 1 : 0)
                        .animation(.linear(duration: 0.3))
                    
                    Text(MainSwiftUI.hijriDateString(date: Date(), isAccessibilityLabel: false))
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding([.trailing, .leading])
                        .foregroundColor(Color(.lightText))
                        .offset(y: sunlightFraction < 0.6 ? -1 * verticalOffset + 24 : -1 * verticalOffset - 12)
                        .accessibilityLabel(MainSwiftUI.hijriDateString(date: Date(), isAccessibilityLabel: true))
                        //                                            .offset(y: 24)
//                        .offset(y: max(24, 45 * (1 - CGFloat(manager.todayTimes.maghrib.timeIntervalSince(manager.todayTimes.sunrise) / 86400))))

                    
                    SineLine(amplitude: amplitude, verticalOffset: 0)//verticalOffset)
                        .stroke(style: StrokeStyle(lineWidth: 2,
                                                   lineCap: .round,
                                                   lineJoin: .round,
                                                   miterLimit: 4,
                                                   dash: [6, 5],
                                                   dashPhase: 0))
//                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        .foregroundColor(Color(.lightText))

                    let sunAppearance = colorForProgress()
                    Circle()
                        .foregroundColor(sunAppearance.1)
                        .shadow(color: sunAppearance.0, radius: sunAppearance.2)
                        .animation(.linear)
//                        .foregroundColor(Color(.lightText))
//                        .foregroundColor(Color(.sRGB, red: 0.517, green: 0.603, blue: 0.702, opacity: 1))
                        .frame(width: g.size.width / 30, height: g.size.width / 30)
                        .offset(x: (isDragging ? manualDayProgress : dayProgress) * g.size.width - 0.5 * g.size.width,
                                y: cos((isDragging ? manualDayProgress : dayProgress) * 2 * CGFloat.pi) * amplitude) //+ verticalOffset)
//                        .animation(.linear(duration: 0.3))
                }
//                Spacer()
            }
//            .border(Color.red)
        }
    }
}

//@available(iOS 13.0.0, *)
//struct SolarViewPreview: PreviewProvider {
//    static var previews: some View {
////        let timeDiff = 10.1 // hours
//
//        SolarView(dayProgress: .constant(0.3), sunlightFraction: 0.6, dhuhrTime: Date(), sunriseTime: Date(timeIntervalSinceNow: -1000))
//            .background(Rectangle()
//                            .foregroundColor(.blue), alignment: .center)
//            .frame(width: 380, height: 200, alignment: .center)
//    }
//}
