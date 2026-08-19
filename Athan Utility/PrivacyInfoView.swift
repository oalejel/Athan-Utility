//
//  PrivacyInfoView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/30/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI

// Shared dark background for the info sheets so text is always readable
// regardless of the system light/dark setting (the app itself is dark-themed).
@available(iOS 13.0.0, *)
private let infoSheetBackground = Color(.sRGB, red: 0.06, green: 0.09, blue: 0.16, opacity: 1)

@available(iOS 13.0.0, *)
private struct InfoSheetCloseButton: View {
    @Binding var isVisible: Bool
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isVisible = false
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.white.opacity(0.5))
                    .font(Font.system(size: 25).bold())
            })
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding([.leading, .trailing, .top])
    }
}

@available(iOS 13.0.0, *)
struct PrivacyInfoView: View {
    @Binding var isVisible: Bool

    var body: some View {
        ZStack {
            infoSheetBackground.edgesIgnoringSafeArea(.all)
            VStack {
                InfoSheetCloseButton(isVisible: $isVisible)

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
                            .foregroundColor(.white.opacity(0.9))
                            .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Acknowledgements

@available(iOS 13.0.0, *)
struct AcknowledgementsView: View {
    @Binding var isVisible: Bool

    // One open-source dependency / contributor row.
    private struct Credit: Identifiable {
        let id = UUID()
        let name: String
        let detail: String
        let url: String?
    }

    private let contributors: [Credit] = [
        Credit(name: "Cuzeth",
               detail: NSLocalizedString("ack_cuzeth_detail", value: "Contributed the iOS 26 AlarmKit Fajr alarm feature.", comment: "Acknowledgement for a code contributor"),
               url: "https://github.com/Cuzeth")
    ]

    private let libraries: [Credit] = [
        Credit(name: "Adhan",
               detail: NSLocalizedString("ack_adhan_detail", value: "Prayer time calculations. By Batoul Apps.", comment: ""),
               url: "https://github.com/batoulapps/adhan-swift"),
        Credit(name: "WhatsNewKit",
               detail: NSLocalizedString("ack_whatsnew_detail", value: "The “What’s New” screen. By Sven Tiigi.", comment: ""),
               url: "https://github.com/SvenTiigi/WhatsNewKit"),
        Credit(name: "TPPDF",
               detail: NSLocalizedString("ack_tppdf_detail", value: "PDF generation for calendar export. By techprimate.", comment: ""),
               url: "https://github.com/techprimate/TPPDF")
    ]

    var body: some View {
        ZStack {
            infoSheetBackground.edgesIgnoringSafeArea(.all)
            VStack {
                InfoSheetCloseButton(isVisible: $isVisible)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundColor(.pink)
                            .font(Font.largeTitle.bold())
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top)

                        Text(Strings.acknowledgements)
                            .foregroundColor(.pink)
                            .bold()
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom)

                        Text(NSLocalizedString("ack_intro", value: "Athan Utility is better thanks to these people and open-source projects.", comment: "Acknowledgements intro"))
                            .foregroundColor(.white.opacity(0.85))
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom)

                        sectionHeader(NSLocalizedString("ack_contributors", value: "Contributors", comment: ""))
                        ForEach(contributors) { creditRow($0) }

                        sectionHeader(NSLocalizedString("ack_open_source", value: "Open-Source Libraries", comment: ""))
                            .padding(.top)
                        ForEach(libraries) { creditRow($0) }
                    }
                    .padding([.leading, .trailing, .bottom])
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline).bold()
            .foregroundColor(.white)
            .padding(.bottom, 6)
    }

    private func creditRow(_ c: Credit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let urlString = c.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text(c.name).font(.subheadline).bold().foregroundColor(.blue)
                        Image(systemName: "arrow.up.right").font(.caption2).foregroundColor(.blue)
                    }
                }
            } else {
                Text(c.name).font(.subheadline).bold().foregroundColor(.white)
            }
            Text(c.detail)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 10).foregroundColor(Color.white.opacity(0.08)))
        .padding(.bottom, 8)
    }
}
