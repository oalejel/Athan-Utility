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
    var body: some View {
        
        ZStack {
            Image("full_moon")
                .scaledToFit()
            Circle()
                .foregroundColor(.black)
        }
        .mask(Circle())
        .shadow(radius: 4)
                
        
    }
}

@available(iOS 13.0.0, *)
struct MoonPreview: PreviewProvider {
    static var previews: some View {
        MoonView()
    }
}
