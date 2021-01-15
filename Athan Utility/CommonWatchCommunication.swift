//
//  CommonWatchCommunication.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 1/15/21.
//  Copyright © 2021 Omar Alejel. All rights reserved.
//

import Foundation


let WATCH_MSG_KEY = "watchmsg"
let PHONE_REPLY_KEY = "phonerep"
let WATCH_REPLY_KEY = "watchrep"
let PHONE_MSG_KEY = "phonemsg"

enum WatchMessage: Int {
    case RequestLocationSettings
}

enum PhoneMessage {
    case LocationSettings
}