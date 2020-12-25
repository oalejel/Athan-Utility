//
//  AthanDefaults.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/23/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import Foundation
import SwiftUI

class AthanDefaults {
    static let shared = AthanDefaults()
    
    static var useCurrentLocation: Bool {
        set { // default is to use current location
            UserDefaults.standard.setValue(!newValue, forKey: "usecustomlocation")
        }
        get {
            return !UserDefaults.standard.bool(forKey: "usecustomlocation")
        }
    }
    
//    @available(iOS 13.0, *)
//    @available(iOSApplicationExtension 13.0, *)
//    static var arabicMode: Binding<Bool> = Binding(
//        get: {
//            print(UserDefaults.standard.value(forKey: "AppleLanguages"))
//            return (UserDefaults.standard.value(forKey: "AppleLanguages") as? [String])?.first == "ar"
//        },
//        set: {
//            if $0 == true {
//                UserDefaults.standard.set(["ar", "Base"], forKey: "AppleLanguages")
//            } else {
//                UserDefaults.standard.set(nil, forKey: "AppleLanguages")
//            }
//            UserDefaults.standard.synchronize()
//        }
//    )
    
    
    
//    {
//        set {
//            if newValue {
//                UserDefaults.standard.set("ar", forKey: "AppleLanguage")
//            } else {
//                UserDefaults.standard.set(["Base"], forKey: "AppleLanguage")
//            }
//            UserDefaults.standard.synchronize()
//        }
//        get {
//            print(UserDefaults.standard.value(forKey: "AppleLanguage"))
//            return UserDefaults.standard.value(forKey: "AppleLanguage") as! String == "ar"
//        }
//    }
    
}
