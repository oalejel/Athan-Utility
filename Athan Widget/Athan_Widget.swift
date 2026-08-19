//
//  Athan_Widget.swift
//  Athan Widget
//
//  Created by Omar Al-Ejel on 9/21/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import Adhan

struct SmallWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                
                Spacer()
                HStack(spacing: 0) {
                    Text(entry.nextPrayerDate, style: .relative)
                        .foregroundColor(.init(UIColor.lightText))
                        .fontWeight(.bold)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.trailing)
                    
                    if Strings.left != "" {
                        Text(" \(Strings.left)")
                            .foregroundColor(.init(UIColor.lightText))
                            .fontWeight(.bold)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer()
            
            PrayerSymbol(prayerType: entry.currentPrayer)
                .foregroundColor(.white)
                .font(.headline)
            HStack {
                Text(entry.currentPrayer.localizedOrCustomString())
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.01)
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                Text(entry.currentPrayer.next().localizedOrCustomString())
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                
                Text(" ")
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                
                Text(entry.nextPrayerDate, style: .time)
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
        }
        //        .padding()
        
    }
}

struct MediumWidget: View {
    var entry: AthanEntry
    @State var progress: CGFloat = 0.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: nil) {
                Text(entry.currentPrayer.localizedOrCustomString())
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: true, vertical: true)
                Text("\(entry.nextPrayerDate, style: .relative) \(Strings.left)")
                    .foregroundColor(.init(UIColor.lightText))
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                Spacer()
                
                PrayerSymbol(prayerType: entry.currentPrayer)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    ForEach(0..<3) { i in
                        Text(Prayer(index: i).localizedOrCustomString())
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 24))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        if i < 2 {
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    ForEach(0..<3) { i in
                        Text(entry.todayPrayerTimes[i], style: .time)
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 24))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        if (i < 2) {
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                Rectangle()
                    .frame(width: 1)
                    .opacity(0.5)
                    .foregroundColor(Color(.lightText))
                
                Spacer()
                
                VStack(alignment: .leading) {
                    ForEach(3..<6) { i in
                        Text(Prayer(index: i).localizedOrCustomString())
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 26))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        
                        if (i < 5) {
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    ForEach(3..<6) { i in
                        Text(entry.todayPrayerTimes[i], style: .time)
                            .foregroundColor(i == entry.currentPrayer.rawValue() ? .green : (i < entry.currentPrayer.rawValue() ? .init(UIColor.lightText) : .white))
                            .font(Font.system(size: 26))
                            .fontWeight(.bold)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                        if (i < 5) {
                            Spacer()
                        }
                    }
                }
            }.padding(.top, 10)
        }
        
    }
}


// MARK: - Extra Large widget (iPad) — minified app view

/// Hijri date string for the widget, reusing the app's transliterated month names
/// (hijriString lives in Global.swift, which is a member of the widget target).
func widgetHijriString(for date: Date) -> String {
    let cal = Calendar(identifier: .islamicUmmAlQura)
    let c = cal.dateComponents([.year, .month, .day], from: date)
    if let y = c.year, let m = c.month, let d = c.day {
        return hijriString(for: m, day: d, year: y)
    }
    return ""
}

/// 2D depiction of the current moon phase, driven by SwiftySuncalc's illumination
/// values (the same engine the in-app MoonView3D uses). `illuminatedFraction` is
/// 0...1; `waxing` puts the lit limb on the right (Northern-hemisphere convention).
@available(iOSApplicationExtension 16.0, *)
struct MoonPhaseView: View {
    let illuminatedFraction: Double
    let waxing: Bool

    var body: some View {
        Canvas { context, size in
            let r = min(size.width, size.height) / 2
            let cx = size.width / 2
            let cy = size.height / 2
            let center = CGPoint(x: cx, y: cy)
            let diskRect = CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)

            // shadowed disk + subtle rim
            context.fill(Path(ellipseIn: diskRect), with: .color(Color.white.opacity(0.10)))
            context.stroke(Path(ellipseIn: diskRect), with: .color(Color.white.opacity(0.22)), lineWidth: 1)

            let k = max(0.0, min(1.0, illuminatedFraction))
            // signed half-width of the terminator ellipse:
            // k=0 (new) -> +r (no light), k=0.5 (quarter) -> 0 (straight), k=1 (full) -> -r (full light)
            let xr = r * (1 - 2 * k)
            let kappa = 0.5522847498 // cubic-bezier circle constant
            let top = CGPoint(x: cx, y: cy - r)

            var lit = Path()
            lit.move(to: top)
            // lit limb: right semicircle, top -> bottom
            lit.addArc(center: center, radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            // terminator: half-ellipse bottom -> top (two cubic quarter curves)
            let mid = CGPoint(x: cx + xr, y: cy)
            lit.addCurve(to: mid,
                         control1: CGPoint(x: cx + xr * kappa, y: cy + r),
                         control2: CGPoint(x: cx + xr,         y: cy + r * kappa))
            lit.addCurve(to: top,
                         control1: CGPoint(x: cx + xr,         y: cy - r * kappa),
                         control2: CGPoint(x: cx + xr * kappa, y: cy - r))
            lit.closeSubpath()

            // waning -> mirror horizontally so the lit limb is on the left
            if !waxing {
                lit = lit.applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: 2 * cx, ty: 0))
            }

            context.fill(lit, with: .color(Color(white: 0.97)))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

@available(iOSApplicationExtension 16.0, *)
struct ExtraLargeWidget: View {
    var entry: AthanEntry

    var body: some View {
        let illum = SwiftySuncalc().getMoonIllumination(date: entry.date)
        let fraction = illum["fraction"] ?? 0
        let waxing = (illum["phase"] ?? 0) < 0.5

        GeometryReader { g in
            HStack(alignment: .top, spacing: 0) {
                // LEFT: hero (current salah + live timer + hijri) over a two-column prayer grid
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        PrayerSymbol(prayerType: entry.currentPrayer)
                            .foregroundColor(.white)
                            .font(.title)
                        Text(entry.currentPrayer.localizedOrCustomString())
                            .foregroundColor(.white)
                            .font(.system(size: 54, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    HStack(spacing: 6) {
                        Text(entry.nextPrayerDate, style: .timer)
                            .foregroundColor(.init(UIColor.lightText))
                            .font(.system(size: 26, weight: .bold))
                            .monospacedDigit()
                        if Strings.left != "" {
                            Text(Strings.left)
                                .foregroundColor(.init(UIColor.lightText))
                                .font(.system(size: 26, weight: .bold))
                        }
                    }
                    .padding(.top, 2)

                    Text(widgetHijriString(for: entry.date))
                        .foregroundColor(.init(UIColor.lightText))
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.top, 1)

                    Spacer(minLength: 14)

                    // two-column prayer grid fills the wide canvas
                    HStack(alignment: .top, spacing: 28) {
                        prayerColumn(range: 0..<3)
                        prayerColumn(range: 3..<6)
                    }
                }

                Spacer(minLength: 16)

                // RIGHT: prominent moon phase, hugging the right edge and filling the height
                MoonPhaseView(illuminatedFraction: fraction, waxing: waxing)
                    .frame(width: min(g.size.height, g.size.width * 0.34),
                           height: min(g.size.height, g.size.width * 0.34))
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 4)
            }
        }
    }

    @ViewBuilder
    func prayerColumn(range: Range<Int>) -> some View {
        VStack(spacing: 0) {
            ForEach(range, id: \.self) { i in
                let p = Prayer(index: i)
                let isCurrent = i == entry.currentPrayer.rawValue()
                let isPast = i < entry.currentPrayer.rawValue()
                let rowColor: Color = isCurrent ? .green : (isPast ? Color(UIColor.lightText) : .white)

                HStack(spacing: 10) {
                    PrayerSymbol(prayerType: p)
                        .foregroundColor(rowColor)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 24, alignment: .center)
                    Text(p.localizedOrCustomString())
                        .foregroundColor(rowColor)
                        .font(.system(size: 21, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer()
                    Text(entry.todayPrayerTimes[i], style: .time)
                        .foregroundColor(rowColor)
                        .font(.system(size: 21, weight: .bold))
                        .monospacedDigit()
                }
                .padding(.vertical, 6)

                if i != range.upperBound - 1 {
                    Rectangle()
                        .fill(Color.white.opacity(0.13))
                        .frame(height: 1)
                }
            }
        }
    }
}

struct SmallErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            Image(systemName: "sun.max")
                .foregroundColor(.white)
            Text(Strings.widgetOpenApp)
                .foregroundColor(.white)
                .font(.body)
                .fontWeight(.bold)
            
        }
        .padding()
    }
}

struct MediumErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Image(systemName: "sun.max")
                        .foregroundColor(.white)
                    Text(Strings.widgetOpenApp)
                        .foregroundColor(.white)
                        .font(.body)
                        .fontWeight(.bold)
                }
                
                Spacer(minLength: 100)
            }
        }
        .padding()
        
    }
}

struct LargeWidget: View {
    var entry: AthanEntry
    var body: some View {
        EmptyView() // TODO: not supported yet
    }
}


struct AccessoryInlineErrorWidget: View {
    var body: some View {
        Text(Strings.widgetOpenApp)
    }
}

struct AccessoryInlineWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        Text(entry.currentPrayer.next().localizedOrCustomString())
        + Text(" at ")
        + Text(entry.nextPrayerDate, style: .time)
    }
}

struct AccessoryRectangularWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(entry.currentPrayer.localizedOrCustomString())
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .padding(.trailing, 2)
                PrayerSymbol(prayerType: entry.currentPrayer)
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 0) {
                Text(entry.currentPrayer.next().localizedOrCustomString())
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
                Text(" ")
                Text(entry.nextPrayerDate, style: .time)
                    .foregroundColor(.init(UIColor.lightText))
                    .fontWeight(.bold)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack(spacing: 0) {
                Text(entry.nextPrayerDate, style: .relative)
                    .foregroundColor(.init(UIColor.lightText))
                    .bold()
                + Text(" \(Strings.left)")
                    .foregroundColor(.init(UIColor.lightText))
                    .bold()
                Spacer()
            }
        }
        
    }
}

struct AccessoryRectangularErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "sun.max")
                .foregroundColor(.white)
            Text(Strings.widgetOpenApp)
                .foregroundColor(.white)
                .font(.body)
                .fontWeight(.bold)
        }
    }
}

struct AccessoryCircularErrorWidget: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "sun.max")
                .foregroundColor(.white)
                .font(.title)
        }
    }
}

struct AccessoryCircularWidget: View {
    var entry: AthanEntry
    var df: RelativeDateTimeFormatter = {
        let d = RelativeDateTimeFormatter()
        d.dateTimeStyle = .numeric
        return d
    }()
    
    var body: some View {
        VStack(alignment: .center) {
            Text(entry.currentPrayer.next().localizedOrCustomString())
                .foregroundColor(.white)
                .font(.caption)
                .fontWeight(.bold)
            Text(entry.nextPrayerDate, style: .time)
                .foregroundColor(.white)
                .font(.caption)
        }
    }
}

struct Athan_WidgetEntryView : View {
    var entry: AthanEntry
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    @ViewBuilder
    var body: some View {
        
        // none means that we have a placeholder
        // nil means error
        switch (family, entry.tellUserToOpenApp || AthanManager.shared.locationSettings.locationName.isEmpty) {
            
            // supported cases with available data
        case (.systemSmall, false):
            SmallWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemMedium, false):
            MediumWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemLarge, false): // ignored since not in supported list
            LargeWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.accessoryRectangular, false):
            AccessoryRectangularWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryInline, false):
            AccessoryInlineWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryCircular, false):
            AccessoryCircularWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
            // error cases (no athan data)
        case (.systemSmall, true):
            SmallErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemMedium, true):
            MediumErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.systemLarge, true): // ignored since not in supported list
            LargeWidget(entry: entry)
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        case (.accessoryRectangular, true):
            AccessoryRectangularErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryInline, true):
            AccessoryInlineErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.accessoryCircular, true):
            AccessoryCircularErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: false, usePadding: false)
        case (.systemExtraLarge, false):
            if #available(iOSApplicationExtension 16.0, *) {
                ExtraLargeWidget(entry: entry)
                    .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
            } else {
                MediumErrorWidget()
                    .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
            }
            // Error version of other currently unsupported widgets...
        case (.systemExtraLarge, true):
            MediumErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        @unknown default:
            SmallErrorWidget()
                .applyContainerBackground(entry: entry, useGradientBackground: true, usePadding: true)
        }
    }
}


struct Athan_Widget: Widget {
    let kind: String = "Athan_Widget"
    
    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            return StaticConfiguration(kind: kind, provider: AthanProvider(), content: { entry in
                Athan_WidgetEntryView(entry: entry)
            })
            .contentMarginsDisabled()
            .configurationDisplayName("Athan Widget")
            // lets not support the .systemLarge family for now...
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])//, .systemLarge])
            .description(Strings.widgetUsefulDescription)
            
        } else {
            // Fallback on earlier versions
            return StaticConfiguration(kind: kind, provider: AthanProvider(), content: { entry in
                Athan_WidgetEntryView(entry: entry)
            })
            .configurationDisplayName("Athan Widget")
            // lets not support the large widget family for now...
            .supportedFamilies([.systemSmall, .systemMedium])//, .systemLarge])
            .description(Strings.widgetUsefulDescription)
        }
    }
}

struct Athan_Widget_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0..<2) { i in
            
            let nextDate = Calendar.current.date(byAdding: .minute, value: 130, to: Date())!
            let entry = AthanEntry(date: Date(),
                                   currentPrayer: Prayer(index: i),
                                   currentPrayerDate: Date(),
                                   nextPrayerDate: nextDate,
                                   todayPrayerTimes: [
                                    nextDate, nextDate, nextDate,
                                    nextDate, nextDate, nextDate
                                   ],
                                   gradient: Gradient(colors: [.black, .blue]))
            // comment this line to test error widgets
            let _: Int = {
                AthanManager.shared.locationSettings.locationName = "San Francisco"
                return 0
            }()
            
            if #available(iOSApplicationExtension 16.0, *) {
                Athan_WidgetEntryView(entry: entry)
                    .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                    .flipsForRightToLeftLayoutDirection(true)
            }
        }
        
        let nextDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let entry = AthanEntry(date: Date(),
                               currentPrayer: .sunrise,
                               currentPrayerDate: Date(),
                               nextPrayerDate: nextDate,
                               todayPrayerTimes: [
                                nextDate, nextDate, nextDate,
                                nextDate, nextDate, nextDate
                               ],
                               gradient: Gradient(colors: [.black, .blue]))
        
        Athan_WidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
