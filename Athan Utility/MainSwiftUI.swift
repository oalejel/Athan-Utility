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
            GeometryReader { g in
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                    .edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 0) {
                            Spacer()
                            MoonView(percentage: 0.3)
                                .frame(width: g.size.width / 3, height: g.size.width / 3, alignment: .center)
                                .offset(y: 12)
                            Spacer()
                        }
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading) {
                                
                                Image(systemName: "sun.max")
                                    .foregroundColor(.white)
                                    .font(Font.system(.title).weight(.medium))
                                Text("Asr")
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.white)
                            }

                            Spacer() // space title | qibla
                            
                            
                            VStack(alignment: .trailing, spacing: 0) {
                                QiblaPointerView(angle: 20)
                                    .frame(width: g.size.width * 0.2, height: g.size.width * 0.2, alignment: .center)
                                    .offset(x: g.size.width * 0.03, y: 0) // offset to let pointer go out

                                HStack {
                                    Text("\("1hr 12m left")")
                                        .fontWeight(.bold)
                                        .autocapitalization(.none)
                                        .foregroundColor(Color(.lightText))
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        
                        ProgressBar(progress: 0.2, lineWidth: 10, outlineColor: .init(white: 1, opacity: 0.2), colors: [.white, .white])

                        let cellFont = Font.system(size: g.size.width * 0.06)
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(0..<6) { i in
                                HStack {
                                    Text(PrayerType(rawValue: i)!.localizedString())
                                        // replace 3 with current prayer index
                                        .foregroundColor((i == 3 ? .green : (i < 3 ? Color(UIColor.lightText) : .white)))
                                        .font(cellFont)
                                        .bold()
                                    Spacer()
                                    Text("11:00 PM")
                                        // replace 3 with current prayer index
                                        .foregroundColor((i == 3 ? .green : (i < 3 ? .init(UIColor.lightText) : .white)))
                                        .foregroundColor(.white)
                                        .font(cellFont)
                                        .bold()
                                }
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                    .padding([.leading, .trailing])
                    
                    ZStack() {
                        SolarView()
                        Text("\("1 Rabiʻ I, 1442")")
                            .fontWeight(.bold)
                            .foregroundColor(Color(.lightText))
                            .offset(y: 24)

                    }
                    
//                        .frame(width: g.size.width, height: g.size.height * 0.2, alignment: .center)

                    Spacer() // space footer
                    
                    
                    HStack(alignment: .center) {
                        Button(action: {
                            print("here")
                        }) {
                            Text("\("Bloomfield Hills, MI")")
                        }
                        .foregroundColor(Color(.lightText))
                        .font(Font.body.weight(.bold))

                        Spacer()
                        
                        Button(action: {
                            print("here")
                        }) {
                            Image(systemName: "gear")
                        }
                        .foregroundColor(Color(.lightText))
                        .font(Font.body.weight(.bold))
                    }
                    .padding([.leading, .trailing, .bottom])
                    .padding([.leading, .trailing, .bottom])
                    
//                    Spacer()
//                    Spacer()
                    
                }
//                .padding()
//                .padding()
                
            }
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
                }
            }
            .padding(.zero)
            .frame(height: lineWidth)
        }
    }
}

@available(iOS 13.0.0, *)
struct MainSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        MainSwiftUI()
            .previewDevice("iPhone Xs")
            
    }
}
