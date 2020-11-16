//
//  MainSwiftUI.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 9/24/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct MainSwiftUI: View {
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: nil) {
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Image(systemName: "sun.max")
                            .foregroundColor(.white)
                            .imageScale(.large)
                        Text("Shurooq")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        Text("time left")
//                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.init(white: 1, opacity: 0.2))
                            .multilineTextAlignment(.center)
                            
                    }

                    Spacer()
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50, alignment: .trailing)
                }
                
                
                
                ProgressBar(progress: 0.2, lineWidth: 10, outlineColor: .init(white: 1, opacity: 0.2), colors: [.white, .white])
                
//                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<6) { i in
                        HStack {
                            Text(PrayerType(rawValue: i)!.localizedString())
                                // replace 3 with current prayer index
                                .foregroundColor((i == 3 ? .green : (i < 3 ? .init(UIColor.lightText) : .white)))
                                .font(.system(size: 26))
                                .bold()
                            Spacer()
                            Text("11:00 PM")
                                // replace 3 with current prayer index
                                .foregroundColor((i == 3 ? .green : (i < 3 ? .init(UIColor.lightText) : .white)))
                                .foregroundColor(.white)
                                .font(.system(size: 26))
                                .bold()
                        }
                    }
                }
                
                
                
                
                Spacer()
                HStack(alignment: .center) {
                    Text("Bloomfield Hills, MI")
                    Button("test") {
                        
                    }
                }
            }
            .padding()
            .padding()
            
        }
        
    }
}

@available(iOS 13.0.0, *)
struct ProgressBar: View {
    var progress: CGFloat
    @State var lineWidth: CGFloat = 7
    @State var outlineColor: Color
    
    var colors: [Color] = [Color.white, Color.white]
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(outlineColor)
                .frame(height: lineWidth)
                .cornerRadius(lineWidth * 0.5)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(colors.first)
                        .frame(width: progress * g.size.width, height: lineWidth)
                        .cornerRadius(lineWidth * 0.5)
                    // having these circles might confuse users
                    //                    HStack(alignment: .center, spacing: 0) {
                    //                        ForEach(0..<5) { index in
                    //                            Circle()
                    //                                .foregroundColor(outlineColor.opacity(0.9))
                    //                                .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                    ////                                .scaledToFit()
                    //                                .position(x: (lineWidth * 0.5) + g.size.width * CGFloat((index / 5)), y: g.size.height * 0.5)
                    //                        }
                    //                    }
                }
            }
            .padding(.zero)
            //            .border(Color.green)
            .frame(height: lineWidth)
            
        }//.frame(idealWidth: 300, idealHeight: 300, alignment: .center)
    }
}


@available(iOS 13.0.0, *)
struct MainSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        MainSwiftUI()
    }
}
