//
//  ActivityIndicator.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 4/16/24.
//  Copyright © 2024 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
