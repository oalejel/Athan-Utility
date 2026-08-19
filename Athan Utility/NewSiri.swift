//
//  NewSiri.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/3/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import SwiftUI
import IntentsUI
import UIKit



@available(iOS 13.0, *)
struct IntentIntegratedController : UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<IntentIntegratedController>) -> IntentController {
        return IntentController()
    }
    
    func updateUIViewController(_ uiViewController: IntentController, context: UIViewControllerRepresentableContext<IntentIntegratedController>) {
    }
    
    typealias UIViewControllerType = IntentController
}



@available(iOS 13.0, *)
class IntentController : UIViewController, INUIAddVoiceShortcutViewControllerDelegate, INUIAddVoiceShortcutButtonDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
//        UIView.appearance().tintColor = .white
        controller.dismiss(animated: true) { }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
//        UIView.appearance().tintColor = .white
        controller.dismiss(animated: true) { }
    }
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
//        UIView.appearance().tintColor = .systemBlue
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)

    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
//        UIView.appearance().tintColor = .systemBlue
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
        
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
//        UIView.appearance().tintColor = .white
        controller.dismiss(animated: true) { }
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
//        UIView.appearance().tintColor = .white
        controller.dismiss(animated: true) { }
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
//        UIView.appearance().tintColor = .white
        controller.dismiss(animated: true) { }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        installButton()
    }

    // Rebuild the button every time the view appears. INUIAddVoiceShortcutButton
    // only re-evaluates whether its shortcut is already added when it's created
    // (or when its own add/edit sheet is dismissed) — it doesn't observe the
    // Shortcuts app. If the user deletes the shortcut there and comes back,
    // recreating the button here makes it flip back to "Add to Siri".
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        installButton()
    }

    private func installButton() {
        // Clear any previous button so state is re-queried from scratch.
        view.subviews.forEach { $0.removeFromSuperview() }

        // Both places this button appears sit on the app's dark background, and
        // `.automaticOutline` was resolving to a white-filled/white-text button
        // that was unreadable there. `.whiteOutline` is deterministic: white
        // label + white border, no fill — always legible on dark.
        let button = INUIAddVoiceShortcutButton(style: .whiteOutline)
        let intent = NextPrayerIntent()
        intent.suggestedInvocationPhrase = "Next prayer time"

        button.shortcut = INShortcut(intent: intent)
        button.delegate = self
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: button.trailingAnchor).isActive = true
    }
}
