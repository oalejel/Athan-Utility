//
//  MoonView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/14/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct MoonView: View {
    @State var percentage: Double = 0.4
    
    var body: some View {
        GeometryReader { g in
            let theta = percentage * Double.pi
//            let width = g.size.width
            let largeRadius = Double(g.size.width * 0.5) / cos(theta)
            let offset = Double(g.size.width * 0.5) - (largeRadius - cos(theta) * largeRadius)
            let offset2 = largeRadius + offset
            
            ZStack {
                Image("full_moon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: g.size.width,
                           height: g.size.width, alignment: .center)
//                Circle()
//                    .frame(width: CGFloat(largeRadius) * 2,
//                           height: CGFloat(largeRadius) * 2,
//                           alignment: .center)
//                    .offset(x: CGFloat((percentage < 0.5) ? offset : offset2), y: 0)
//                    .border(Color.blue)
            }
            .frame(width: g.size.width, height: g.size.width, alignment: .center)
//            .border(Color.red)
//            .mask(
//                Circle()
//                    .frame(width: CGFloat(largeRadius) * 2,
//                           height: CGFloat(largeRadius) * 2,
//                           alignment: .center)
//                    .offset(x: CGFloat(offset), y: 0)
//            )
            .shadow(radius: 4)

        }
    }
}

@available(iOS 13.0.0, *)
struct MoonPreview: PreviewProvider {
    static var previews: some View {
        MoonView()
    }
}
