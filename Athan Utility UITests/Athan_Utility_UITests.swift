//
//  Athan_Utility_UITests.swift
//  Athan Utility UITests
//
//  Created by Omar Al-Ejel on 7/15/18.
//  Copyright © 2018 Omar Alejel. All rights reserved.
//

import XCTest

class Athan_Utility_UITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testScreenshotInteraction() {
        let translatedContinue = NSLocalizedString("Continue", comment: "")
        let whatsNewButton = app.buttons[translatedContinue]
        if whatsNewButton.exists {
            whatsNewButton.tap()
        }
        
        app.buttons["qibla"].tap()
        snapshot("02Qibla")
        app.buttons["done"].tap()
        snapshot("01MainScreen")
        app.buttons["notification settings"].tap()
        snapshot("03NotificationsSettings")
        app.buttons["done"].tap()
        app.buttons["location"].tap()
        snapshot("04LocationControl")
        
        
    
//        let locationElement = app.otherElements.containing(.button, identifier:"location").element
//        locationElement.tap()
//
//        snapshot("02LocationControl")
//
//        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element
//        element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.tap()
//        element.tap()
//        app.buttons["qibla"].tap()
//        app.buttons["done"].tap()
//        app.buttons["notification settings"].tap()
//        app.navigationBars["Alarms"].buttons["Done"].tap()
        
        
//        app.navigationBars["Location Search"].buttons["Cancel"].tap()
//        snapshot("01MainScreen")
//        app.buttons["qibla"].tap()
//        snapshot("03Qibla")
//        app.buttons["notification settings"].tap()
//        snapshot("04NotificationsSettings")
    }
    
}
