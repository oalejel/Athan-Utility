//
//  QiblaPointerView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/14/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct QiblaPointerView: View {
    private let pointerLength: CGFloat = 60
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Rectangle()
                    .foregroundColor(.black)
                Image("kaba_2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: (g.size.width - pointerLength * 2) / 3, height:  (g.size.width - pointerLength * 2) / 3, alignment: .center)
                
                Circle()
                    .stroke(Color.white, lineWidth: (g.size.width - pointerLength) / 10)
                    .padding(g.size.width / 20 + pointerLength)
            }
        }
        
        
        
        
    }
}

@available(iOS 13.0.0, *)
struct QiblaPointerPreview: PreviewProvider {
    static var previews: some View {
        QiblaPointerView()
    }
}
