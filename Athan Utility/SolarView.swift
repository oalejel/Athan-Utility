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
    // Tapping the Hijri date floats a callout over it. The Gregorian date lives
    // inside that callout now, rather than in a separate capsule of its own.
    @ObservedObject private var callout = HijriCalloutState.shared
    // Bumped whenever the calendar or offset changes, to force the date line to
    // re-render with the new setting.
    @State private var hijriRevision = 0
    // Measured height of the callout, used to lift it clear above the date line.
    @State private var calloutHeight: CGFloat = 0
    @ObservedObject private var browse = DayBrowseState.shared

    /// The date text itself, plus the yellow day-delta while browsing another day.
    private var hijriDateLine: some View {
        HStack(spacing: 6) {
            Text(MainSwiftUI.hijriDateString(date: browse.displayDate, isAccessibilityLabel: false))
                .fontWeight(.bold)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color(.lightText))
                .id(hijriRevision)
            if !browse.offsetLabel.isEmpty {
                Text(browse.offsetLabel)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .transition(.opacity)
            }
        }
        .padding([.leading, .trailing], 8)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) { callout.isPresented.toggle() }
        }
        .accessibilityLabel(MainSwiftUI.hijriDateString(date: browse.displayDate, isAccessibilityLabel: true))
        .accessibilityHint(Text(NSLocalizedString("hijri_tap_hint", value: "Double-tap to show today's Gregorian date and calendar options", comment: "")))
    }

    /// A day-stepping chevron. Occupies its slot at all times so revealing the arrows
    /// doesn't shove the date sideways — it only fades and slides in.
    private func dayArrow(systemName: String, delta: Int) -> some View {
        Button {
            browse.step(delta)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(.lightText))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(browse.isActive ? 1 : 0)
        .allowsHitTesting(browse.isActive)
        .accessibilityLabel(Text(delta < 0
            ? NSLocalizedString("day_previous", value: "Previous day", comment: "")
            : NSLocalizedString("day_next", value: "Next day", comment: "")))
        .accessibilityHidden(!browse.isActive)
    }

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
                    .animation(.linear(duration: 0.3), value: isDragging)

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
                        // Fade the ends so the line doesn't hit the window edges hard
                        // (looks cleaner in the wide macOS window).
                        .mask(
                            LinearGradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .white, location: 0.10),
                                .init(color: .white, location: 0.90),
                                .init(color: .clear, location: 1.0)
                            ], startPoint: .leading, endPoint: .trailing)
                        )
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
                        .animation(.linear(duration: 0.3), value: isDragging)
                    
                    VStack(spacing: 4) {
                        HStack(spacing: 0) {
                            dayArrow(systemName: "chevron.left", delta: -1)
                            hijriDateLine
                            dayArrow(systemName: "chevron.right", delta: 1)
                        }
                            // An overlay, deliberately, so the date and everything below it
                            // stay put. The overlay is pinned to the date's TOP edge and then
                            // lifted by its own measured height, which puts it fully above the
                            // date with its tail pointing back down at it.
                            //
                            // Measuring is not optional here: an .alignmentGuide on the callout
                            // is swallowed by the enclosing Group (the overlay aligns the Group,
                            // whose own guide stays at its default), so the callout landed on
                            // top of the date instead of above it.
                            .overlay(
                                Group {
                                    if callout.isPresented {
                                        HijriCalloutView(
                                            onChange: { hijriRevision += 1 },
                                            onDone: {
                                                withAnimation(.easeInOut(duration: 0.2)) { callout.isPresented = false }
                                            }
                                        )
                                        .fixedSize()
                                        .background(
                                            GeometryReader { cg in
                                                Color.clear.preference(key: HijriCalloutHeightKey.self,
                                                                       value: cg.size.height)
                                            }
                                        )
                                        .offset(y: -(calloutHeight + 6))
                                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
                                    }
                                },
                                alignment: .top
                            )
                            .onPreferenceChange(HijriCalloutHeightKey.self) { calloutHeight = $0 }
                    }
                    .offset(y: sunlightFraction < 0.6 ? -1 * verticalOffset + 24 : -1 * verticalOffset - 12)
                    // The sine curve and the sun are later children of this ZStack, so
                    // without this the callout renders behind them and the text is
                    // unreadable where they cross.
                    .zIndex(callout.isPresented ? 10 : 0)
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
                        // Fade the dashed curve's ends to match the horizon line.
                        .mask(
                            LinearGradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .white, location: 0.10),
                                .init(color: .white, location: 0.90),
                                .init(color: .clear, location: 1.0)
                            ], startPoint: .leading, endPoint: .trailing)
                        )

                    let sunAppearance = colorForProgress()
                    let sunSize = g.size.width / 30
                    // Layered sun: a soft atmospheric halo, a radial bright-to-warm core, and a
                    // small specular glint for a realistic sense of glare/brightness.
                    ZStack {
                        Circle()
                            .fill(sunAppearance.1)
                            .frame(width: sunSize * 2.8, height: sunSize * 2.8)
                            .blur(radius: sunSize * 0.9)
                            .opacity(0.45)
                        Circle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [.white, sunAppearance.1, sunAppearance.1.opacity(0.9)]),
                                               center: UnitPoint(x: 0.4, y: 0.36),
                                               startRadius: 0, endRadius: sunSize * 0.75)
                            )
                            .frame(width: sunSize, height: sunSize)
                            .shadow(color: sunAppearance.0, radius: sunAppearance.2)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: sunSize * 0.3, height: sunSize * 0.3)
                                    .blur(radius: sunSize * 0.14)
                                    .offset(x: -sunSize * 0.15, y: -sunSize * 0.18)
                                    .opacity(0.95)
                            )
                    }
                    // No implicit position animation: drag smoothness comes from the gesture's
                    // explicit withAnimation; an implicit animation lurches the sun on window resize.
                    .offset(x: (isDragging ? manualDayProgress : dayProgress) * g.size.width - 0.5 * g.size.width,
                            y: cos((isDragging ? manualDayProgress : dayProgress) * 2 * CGFloat.pi) * amplitude)
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
