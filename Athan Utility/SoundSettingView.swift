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
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.athanSound)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .onAppear {
                    viewSelectedSound = tempNotificationSettings.selectedSound
                }
                .padding([.leading, .top])
                .padding([.leading, .top])

            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: nil) {
                    
                    ForEach(0..<NotificationSettings.Sounds.allCases.count) { sIndex in
                        ZStack {
                            Button(action: {
                                // play sound effect
                                // set setting, making checkmark change
                                withAnimation {
                                    viewSelectedSound = NotificationSettings.Sounds(rawValue: sIndex)!
                                    tempNotificationSettings.selectedSound = viewSelectedSound
                                    NoteSoundPlayer.playFullAudio(for: sIndex)
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
                            .buttonStyle(ScalingButtonStyle())
                        }
                    }
                }
                .padding()
                .padding([.leading, .trailing])
            }
            
            HStack(alignment: .center) {
                Spacer()
                
                Button(action: {
                    // tap vibration
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // save
                    tempNotificationSettings.selectedSound = viewSelectedSound
                    AthanManager.shared.notificationSettings = tempNotificationSettings
                    NoteSoundPlayer.fadeAndStopAudio() // fade out any potentially playing sounds
                    withAnimation {
                        self.activeSection = .General
                    }
                }) {
                    Text(Strings.done)
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
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            SoundSettingView(tempNotificationSettings: .constant(NotificationSettings(settings: [:], selectedSound: .makkah)), activeSection: .constant(.Sounds))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}
