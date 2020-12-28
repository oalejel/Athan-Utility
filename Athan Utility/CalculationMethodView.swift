//
//  CalculationMethodView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/27/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import Adhan

@available(iOS 13.0.0, *)
struct CalculationMethodView: View {
    
    #warning("make sure updating this value changes earlier settings?")
    @Binding var tempPrayerSettings: PrayerSettings
    @State var viewSelectedMethod = CalculationMethod.northAmerica
    
    @Binding var activeSection: SettingsSectionType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Calculation Method")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .onAppear {
                    viewSelectedMethod = tempPrayerSettings.calculationMethod
                }
                .padding([.leading, .trailing, .top])

            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: nil) {
                    
                    ForEach(0..<CalculationMethod.allCases.count) { mIndex in
                        ZStack {
                            Button(action: {
                                // play sound effect
                                // set setting, making checkmark change
                                withAnimation {
                                    viewSelectedMethod = CalculationMethod(index: mIndex)
                                    tempPrayerSettings.calculationMethod = viewSelectedMethod
                                }
                            }, label: {
                                HStack {
                                    Text(CalculationMethod(index: mIndex).stringValue())
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding()
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(Font.headline.weight(.bold))
                                        .padding()
                                        .opacity(viewSelectedMethod == CalculationMethod(index: mIndex) ? 1 : 0)
                                }
                            })
                            .buttonStyle(ScalingButtonStyle())
                        }
                    }
                }
                .padding()
            }
            
            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    // tap vibration
                    let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                    lightImpactFeedbackGenerator.impactOccurred()
                    withAnimation {
                        self.activeSection = .General
                    }
                }) {
                    Text("Done")
                        .foregroundColor(Color(.lightText))
                        .font(Font.body.weight(.bold))
                }
            }
            .padding()
            .padding([.leading, .trailing, .bottom])

        }
        
    }
}

@available(iOS 13.0.0, *)
struct MethodSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                .edgesIgnoringSafeArea(.all)
            CalculationMethodView(tempPrayerSettings: .constant(PrayerSettings(method: .dubai, madhab: .shafi, customNames: [:])), activeSection: .CalculationMethod)
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}
