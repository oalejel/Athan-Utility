//
//  SoundSettingView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/2/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct SoundSettingView: View {
    
    #warning("make sure updating this value changes earlier settings?")
    @Binding var tempNotificationSettings: NotificationSettings
    @State var viewSelectedSound = NotificationSettings.Sounds.ios_default
    @Binding var activeSection: SettingsSectionType
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: nil) {
                    
                    Text("Notification sound")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.bottom)
                        .onAppear {
                            viewSelectedSound = tempNotificationSettings.selectedSound
                        }
                    ForEach(0..<NotificationSettings.Sounds.allCases.count) { sIndex in
                        ZStack {
                            Button(action: {
                                // play sound effect
                                // set setting, making checkmark change
                                withAnimation {
                                    viewSelectedSound = NotificationSettings.Sounds(rawValue: sIndex)!
                                    tempNotificationSettings.selectedSound = viewSelectedSound
                                }
                            }, label: {
                                HStack {
                                    Text(NotificationSettings.Sounds(rawValue: sIndex)!.localizedString())
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                        .padding()
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(Font.headline.weight(.bold))
                                        .padding()
                                        .opacity(viewSelectedSound.rawValue == sIndex ? 1 : 0)
                                }
                            })
                            .buttonStyle(GradientButtonStyle())
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
struct SoundSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                .edgesIgnoringSafeArea(.all)
            SoundSettingView(tempNotificationSettings: .constant(NotificationSettings(settings: [:])), activeSection: .constant(.Sounds))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}
