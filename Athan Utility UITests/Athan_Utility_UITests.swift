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

    /// Walks every screen with dwell time — meant to be screen-recorded into a demo video.
    func testDemoWalkthrough() {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_DEMO"]
        app.launch()

        let settings = app.buttons["settingsButton"]
        _ = settings.waitForExistence(timeout: 15)
        sleep(3) // linger on the main screen

        // Discover features → a feature detail → back → done
        let discover = app.buttons["discoverButton"]
        if discover.waitForExistence(timeout: 5) {
            discover.tap(); sleep(3)
            let widgetsRow = app.cells.element(boundBy: 1)
            if widgetsRow.waitForExistence(timeout: 4) {
                widgetsRow.tap(); sleep(3)
                let back = app.navigationBars.buttons.element(boundBy: 0)
                if back.exists { back.tap(); sleep(1) }
            }
            let done = app.buttons["discoverDone"]
            if done.waitForExistence(timeout: 4) { done.tap(); sleep(1) }
        }

        // Settings — scroll through, then back
        settings.tap(); sleep(3)
        app.swipeUp(); sleep(2)
        app.swipeDown(); sleep(1)
        let settingsDone = app.buttons["settingsDoneButton"]
        if settingsDone.waitForExistence(timeout: 5) { settingsDone.tap(); sleep(1) }

        // Location
        let location = app.buttons["locationButton"]
        if location.waitForExistence(timeout: 5) {
            location.tap(); sleep(3)
            let locationDone = app.buttons["locationDoneButton"]
            if locationDone.waitForExistence(timeout: 5) { locationDone.tap(); sleep(1) }
        }

        // Monthly calendar
        let calendar = app.buttons["calendarButton"]
        if calendar.waitForExistence(timeout: 5) {
            calendar.tap(); sleep(4)
        }
        sleep(2)
    }

    /// Discover screens, captured in their own launch: the light-bulb hint has to be
    /// visible to reach them, and it would otherwise sit on top of the main screenshot.
    func testDiscoverScreenshots() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_DEMO", "-UITEST_DISCOVER"]
        setupSnapshot(app)
        app.launch()

        let discover = app.buttons["discoverButton"]
        guard discover.waitForExistence(timeout: 15) else {
            XCTFail("Discover hint never appeared")
            return
        }
        discover.tap()
        sleep(1)
        snapshot("05Discover")

        // icon header is cell 0; widgets is the first feature (cell 1)
        let widgetsRow = app.cells.element(boundBy: 1)
        if widgetsRow.waitForExistence(timeout: 4) {
            widgetsRow.tap()
            sleep(1)
            snapshot("06Widgets")
        }
    }
}
