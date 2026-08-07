//
//  Athan_Utility_UITests.swift
//  Athan Utility UITests
//
//  Created by Omar Al-Ejel on 7/15/18.
//  Copyright © 2018 Omar Alejel. All rights reserved.
//

import XCTest

@MainActor
class Athan_Utility_UITests: XCTestCase {

    /// Walks the main feature screens, capturing a hero shot of each step.
    func testScreenshotInteraction() {
        continueAfterFailure = false
        let app = XCUIApplication()
        // Seed deterministic demo state (fixed location, no onboarding / What's New).
        app.launchArguments += ["-UITEST_DEMO"]
        setupSnapshot(app)
        app.launch()

        // 01 — main screen: next prayer, all prayer times, Qibla pointer, day arc
        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(settings.waitForExistence(timeout: 15), "Main screen did not appear")
        snapshot("01Main")

        // 05 — feature discovery (light bulb hint → Tips-style list)
        let discover = app.buttons["discoverButton"]
        if discover.waitForExistence(timeout: 5) {
            discover.tap()
            sleep(1)
            snapshot("05Discover")
            // icon header is cell 0; widgets is the first feature (cell 1)
            let widgetsRow = app.cells.element(boundBy: 1)
            if widgetsRow.waitForExistence(timeout: 4) {
                widgetsRow.tap()
                sleep(1)
                snapshot("06Widgets")
                let back = app.navigationBars.buttons.element(boundBy: 0)
                if back.exists { back.tap() }
            }
            let done = app.buttons["discoverDone"]
            if done.waitForExistence(timeout: 4) { done.tap() }
        }

        // 02 — settings
        settings.tap()
        snapshot("02Settings")
        let settingsDone = app.buttons["settingsDoneButton"]
        if settingsDone.waitForExistence(timeout: 5) { settingsDone.tap() }

        // 03 — location
        let location = app.buttons["locationButton"]
        if location.waitForExistence(timeout: 5) {
            location.tap()
            snapshot("03Location")
            let locationDone = app.buttons["locationDoneButton"]
            if locationDone.waitForExistence(timeout: 5) { locationDone.tap() }
        }

        // 04 — calendar (monthly prayer times)
        let calendar = app.buttons["calendarButton"]
        if calendar.waitForExistence(timeout: 5) {
            calendar.tap()
            snapshot("04Calendar")
        }
    }

    /// Captures the first-launch intro settings (with the country recommendation).
    func testIntroScreenshot() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_INTRO"]
        setupSnapshot(app)
        app.launch()
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 15)
        sleep(2) // let the recommendation resolve + layout settle
        snapshot("00Intro")
    }
}
