//
//  GetThuhr.swift
//  AthanSiriIntents
//
//  Created by Omar Al-Ejel on 10/15/23.
//  Copyright © 2023 Omar Alejel. All rights reserved.
//

import Foundation
import AppIntents

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct GetThuhr: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "GetThuhrIntent"

    static var title: LocalizedStringResource = "Thuhr Time"
    static var description = IntentDescription("Get upcoming Thuhr time.")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Thuhr Athan Time")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: ()) {  in
            DisplayRepresentation(
                title: "Get Thuhr Athan Time",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult & ReturnsValue<DateComponents> {
        // TODO: Place your refactored intent handler code here.
        return .result(value: DateComponents(/* fill in result initializer here */))
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func responseSuccess(prayerName: IntentPrayerOptionAppEnum, prayerDate: DateComponents, recentLocation: String) -> Self {
        "\(prayerName) starts at \(prayerDate) in \(recentLocation)"
    }
    static var responseFailure: Self {
        "Unable to find prayer time."
    }
}

