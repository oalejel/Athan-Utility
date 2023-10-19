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
    @Binding var angle: Double
    @Binding var qiblaAngle: Double // correct angle, which we should highlight and vibrate for
    @Binding var hidePointer: Double
    var body: some View {
        GeometryReader { g in
            let pointerLength = g.size.width / 6
            let lineWidth = (g.size.width - pointerLength) / 13
            
            ZStack {
                Image("kaba")
                    .resizable()
                    .scaledToFit()
                    .frame(width: (g.size.width - pointerLength * 2) / 2.2,
                           height:  (g.size.width - pointerLength * 2) / 2.2,
                           alignment: .center)
                Circle()
                    .strokeBorder(Color.white, lineWidth: lineWidth)
                    .padding(pointerLength)
                
                if hidePointer < 0.001 {
                    Triangle()
                        .frame(width: pointerLength * 1.2, height: pointerLength, alignment: .center)
                        .offset(x: 0, y: (g.size.width / -2) - lineWidth + pointerLength)
                        .foregroundColor(.white)
    //                    .rotationEffect(.degrees(angle), anchor: .center)
                        .shortRotationEffect(.degrees(UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft ? angle - qiblaAngle : qiblaAngle - angle), id: 1)
                        .animation(Animation.default.speed(1))
                        .transition(.opacity)
                }
            }
        }
    
    }
}


infix operator %% : DefaultPrecedence
extension Double {
    
    /// Returns modulus, but forces it to be positive
    /// - Parameters:
    ///   - left: number
    ///   - right: modulus
    /// - Returns: positive modulus
    static  func %% (_ left: Double, _ right: Double) -> Double {
        let truncatingRemainder = left.truncatingRemainder(dividingBy: right)
        return truncatingRemainder >= 0 ? truncatingRemainder : truncatingRemainder+abs(right)
    }
}

@available(iOS 13.0.0, *)
extension View {
    
    /// Like RotationEffect - but when animated, the rotation moves in the shortest direction.
    /// - Parameters:
    ///   - angle: new angle
    ///   - anchor: anchor point
    ///   - id: unique id for the item being displayed. This is used as a key to maintain the rotation history and figure out the right direction to move
    func shortRotationEffect(_ angle: Angle,anchor: UnitPoint = .center, id:Int) -> some View {
        modifier(ShortRotation(angle: angle,anchor:anchor, id:id))
    }
}

@available(iOS 13.0.0, *)
struct ShortRotation: ViewModifier {
    static var storage:[Int:Angle] = [:]
    
    var angle:Angle
    var anchor:UnitPoint
    var id:Int
    
func getAngle() -> Angle {
    var newAngle = angle
    
    if let lastAngle = ShortRotation.storage[id] {
        let change:Double = (newAngle.degrees - lastAngle.degrees) %% 360.0
          
        if change < 180 {
            newAngle = lastAngle + Angle.init(degrees: change)
        }
        else {
            newAngle = lastAngle + Angle.init(degrees: change - 360)
        }
    }
    
    ShortRotation.storage[id] = newAngle

    return newAngle
}
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(getAngle(),anchor: anchor)
    }
}

@available(iOS 13.0.0, *)
struct QiblaPointerPreview: PreviewProvider {
    static var previews: some View {
        QiblaPointerView(angle: .constant(10), qiblaAngle: .constant(13), hidePointer: .constant(0))
            .background(Rectangle(), alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}
