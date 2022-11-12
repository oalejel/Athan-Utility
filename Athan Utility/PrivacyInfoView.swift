//
//  PrivacyInfoView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/30/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

/*
 Privacy Icon in system blue
 Privacy
 
 I developed this ad-free, 100% private athan app
 because athan apps have no reason to collect our muslim brothers and sisters' data.
 Athan Utility calculates everything on-device. When given permissions, iOS location
 services simply allow athan utility to conveniently refresh
 calculation coordinates so that you don't have to enter approximate coordinates
 every time you visit a new city. By Allah, this app will never be allowed to betray
 its users.
 
 Athan Utility's code is public for viewing at github.com/oalejel/athan-utility.
 You can verify that Athan Utility does not collect or share any user data by
 downloading and running the app on your device with Xcode. You can also read through
 my exasperated code commit messages at your leisure. You could probably prove that athan utility works without sharing data
 by scanning for outgoing http requests from athan utility (there are none).
 
 If you have any doubts about athan utility, please reach out to me on twitter @oalejel or
 email me with the feedback button.
 
 If you enjoy using Athan Utility, please share it with friends and give it a review on the app store!
 
 */

@available(iOS 13.0.0, *)
struct PrivacyInfoView: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack {
            HStack { // main calendar header
                Spacer()
                VStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isVisible = false
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.tertiaryLabel))
                            .font(Font.system(size: 25).bold())
                    })
                    Spacer()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding([.leading, .trailing, .top])
            
        ScrollView {
            VStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.blue)
                    .font(Font.largeTitle.bold())
                    .padding([.top])
                    .padding([.top])
                
                Text(Strings.privacyNotes)
                    .foregroundColor(.blue)
                    .bold()
                    .font(.body)
                    .padding([.bottom])
                    .padding([.bottom])
                
                let text =
                    """
I developed this ad-free, 100% private athan app because athan apps have no reason to collect our data. \
Athan Utility calculates everything on-device. If given permissions, iOS location services simply allow athan utility \
to conveniently refresh calculation coordinates so that you don't have to enter approximate coordinates \
every time you visit a new city. By Allah, this app will never be allowed to betray its users.

Athan Utility's code is public for viewing at github.com/oalejel/athan-utility. \
You can verify that Athan Utility does not collect / share any user data by \
downloading and running the app on your device with Xcode. You can also read through \
my exasperated code commit messages at your leisure.

If you have any doubts about Athan Utility, please reach out to me on Twitter @oalejel or \
email me with the feedback button.

If you enjoy using Athan Utility, please share it with friends and give it a review on the App Store! \
If you *really* like Athan Utility, please donate to people in need. This app will always be free.
"""
                Text(text)
                    .padding()
            }
        }
        }
        
    }
    
}
