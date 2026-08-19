//
//  LocationSettingsView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/20/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import SwiftUI
import CoreLocation.CLLocation
import MapKit
import Adhan

@available(iOS 13.0.0, *)
struct LocationSettingsView: View, Equatable {
    
    static func == (lhs: LocationSettingsView, rhs: LocationSettingsView) -> Bool {
        // << return yes on view properties which identifies that the
        // view is equal and should not be refreshed (ie. `body` is not rebuilt)
        return (lhs.usingCurrentLocation == rhs.usingCurrentLocation
                    && lhs.locationPermissionGranted == rhs.locationPermissionGranted && rhs.unboundCoordinate.latitude == lhs.unboundCoordinate.latitude)
    }
    
    #warning("make sure updating this value changes earlier settings?")
    
    // start text field as a copy of the location settings loc name
    @State var textFieldText: String = "\(AthanManager.shared.locationSettings.locationName)"
    
    // state shared with map view. save coordinate, usingcurrent, and name on exit
    @State var boundCoordinate = AthanManager.shared.locationSettings.locationCoordinate
    @State var unboundCoordinate = AthanManager.shared.locationSettings.locationCoordinate
    @State var usingCurrentLocation = AthanManager.shared.locationSettings.useCurrentLocation
    
    @State var timeZone = AthanManager.shared.locationSettings.timeZone
    // ISO country code resolved by the geocoder for the currently selected location,
    // used to auto-suggest a calculation method on save.
    @State var detectedCountryCode: String? = AthanManager.shared.locationSettings.countryCode

    @State var templocationSettings: LocationSettings = AthanManager.shared.locationSettings.copy() as! LocationSettings
    @Binding var parentSession: PresentedSectionType // used to trigger transition back
    
    @Binding var locationPermissionGranted: Bool
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State var awaitingLocationUpdate = false
    @State var awaitingUserSearchLookup = false
    // is the currently inputted location string understandable
    @State var erroneousLocation = false
    
    @State var timer: Timer?
    
    let geocoder = CLGeocoder()
    var mapView: MapView?
        
    @State var localizedCurrentPrayer: Prayer = ObservableAthanManager.shared.currentPrayer
    @State var appearanceCopy = ObservableAthanManager.shared.appearance

    // Onboarding: compact "recommended settings" card + optional editor sheet,
    // shown in place of the old forced calculation-preferences step.
    @State private var showingSettingsEditor = false
    @State private var userEditedCalcSettings = false
    @State private var cardMethod: CalculationMethod = AthanManager.shared.prayerSettings.calculationMethod
    @State private var cardMadhab: Madhab = AthanManager.shared.prayerSettings.madhab
    @State private var cardLatRule: HighLatitudeRule = AthanManager.shared.prayerSettings.latitudeRule ?? .middleOfTheNight

    private var recommendedMethodForLocation: CalculationMethod {
        if let cc = detectedCountryCode, !cc.isEmpty { return CalculationMethod.recommended(forISOCountryCode: cc) }
        return AthanManager.shared.prayerSettings.calculationMethod
    }
    private func syncCardFromRecommendation() {
        guard !userEditedCalcSettings else { return } // don't clobber the user's edits
        cardMethod = recommendedMethodForLocation
        cardLatRule = HighLatitudeRule.recommended(for: unboundCoordinate)
    }
    private func syncCardFromManager() {
        cardMethod = AthanManager.shared.prayerSettings.calculationMethod
        cardMadhab = AthanManager.shared.prayerSettings.madhab
        cardLatRule = AthanManager.shared.prayerSettings.latitudeRule ?? .middleOfTheNight
    }
    /// Seed the manager with the card's values so the editor opens on them, then present it.
    private func openSettingsEditor() {
        let ps = AthanManager.shared.prayerSettings
        ps.calculationMethod = cardMethod
        ps.madhab = cardMadhab
        ps.latitudeRule = cardLatRule
        AthanManager.shared.prayerSettings = ps
        showingSettingsEditor = true
    }

    func updateLocalizedPrayer(coord: CLLocationCoordinate2D) {
        let times = AthanManager.shared.calculateTimes(referenceDate: Date(), customCoordinate: unboundCoordinate, customTimeZone: timeZone, adjustments: AthanManager.shared.notificationSettings.adjustments())
        localizedCurrentPrayer = times?.currentPrayer() ?? .isha
    }
    
    let x: Int = {
        UITextField.appearance().clearButtonMode = .always
        UITextField.appearance().tintColor = .white
        AthanManager.shared.requestLocationPermission()
        return 0
    }()
    
    var body: some View {
        ZStack {
            GradientView(currentPrayer: $localizedCurrentPrayer, appearance: $appearanceCopy)
                .equatable()
            
            GeometryReader { g in
                VStack(alignment: .leading) {
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Strings.setLocation)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.01)
                            .padding(.bottom)
                        
                        ZStack {
                            MapView(center: $boundCoordinate, usingCurrentLocation: $usingCurrentLocation) { loc in
                                // if the source of the update is not a manual input,
                                // we don't want to set the location name
                                if !usingCurrentLocation {
                                    awaitingUserSearchLookup = true
                                    print("creating timer")
                                    unboundCoordinate = loc
                                    boundCoordinate = loc
//                                    updateLocalizedPrayer(coord: unboundCoordinate)
                                    timer?.invalidate()
                                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { t in
                                        queryAndSaveCoordinate(coord: loc)
                                    }
                                }
                            }
                            .equatable()
                            .cornerRadius(12)
                            
                            VStack {
                                Image(systemName: "mappin")
                                    .font(Font.title.weight(.bold))
                                    .shadow(radius: 2)
                                    .foregroundColor(Color(.red))
                                
                                Image(systemName: "mappin")
                                    .font(Font.title.weight(.bold))
                                    .opacity(0)
                            }
                            .allowsHitTesting(false)
                            
                            VStack {
                                HStack(spacing: 4) {
                                    HStack {
                                        //                                Image(systemName: "mappin.and.ellipse")
                                        //                                    .foregroundColor(Color(.label))
                                        //                                    .font(.subheadline)
                                        Text("\(unboundCoordinate.latitude, specifier: "%.2f")˚, \(unboundCoordinate.longitude, specifier: "%.2f")˚")
                                            .foregroundColor(Color(.secondaryLabel))
                                            .font(.subheadline)
                                    }
                                    .padding(4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color(.tertiaryLabel), lineWidth: 1)
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.tertiarySystemBackground))
                                    )
                                    Spacer()
                                }
                                .padding()
                                Spacer()
                            }
                        }
                    }
                    
                    
                    // Compact one-line recommended settings — tap to edit (opens the full editor, incl. High-Latitude).
                    if !IntroSetupFlags.hasCompletedCalculationSetup {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            openSettingsEditor()
                        }) {
                            HStack(spacing: 6) {
                                (Text(NSLocalizedString("method_colon", value: "Method: ", comment: "Prefix on the compact settings line"))
                                    .foregroundColor(Color(.lightText))
                                 + Text(cardMethod.localizedString()).foregroundColor(.white).fontWeight(.semibold)
                                 + Text(", ").foregroundColor(Color(.lightText))
                                 + Text(cardMadhab.stringValue()).foregroundColor(.white).fontWeight(.semibold))
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer(minLength: 4)
                                Image(systemName: "slider.horizontal.3")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Color(.lightText))
                            }
                            .padding(.vertical, 9)
                            .padding(.horizontal, 12)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.1)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 4)
                        .accessibilityIdentifier("recommendedSettingsLine")
                    }

                    // Input text field for location
                    if !usingCurrentLocation {
                        HStack {
                            HStack {
                            if awaitingUserSearchLookup {
                                ActivityIndicator(isAnimating: .constant(true), style: .white)
                            }
                            
                            Text(Strings.locationColon)
                                .foregroundColor(erroneousLocation ? .red : .white)
                                .bold()
                            }
                                .padding([.leading])
                            TextField(Strings.searchCity, text: $textFieldText) { isEditing in
                                if isEditing {
                                    erroneousLocation = false // reset potential error
                                }
                            } onCommit: {
                                // if we have a degree symbol, or a comma between two numbers, only attempt to query coordinat
                                if textFieldText.contains(",") {
                                    // use shorter of the two substrings
                                    let rep1 = textFieldText.replacingOccurrences(of: "°", with: "")
                                    let rep2 = rep1.replacingOccurrences(of: " ", with: "")
                                    let split = rep2.split(separator: ",")
                                    
                                    if split.count == 2 {
                                        if let lat = CLLocationDegrees(split[0]), let lon = CLLocationDegrees(split[1]) {
                                            awaitingUserSearchLookup = true
                                            queryAndSaveCoordinate(coord: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                            return
                                        }
                                    }
                                }
                                awaitingUserSearchLookup = true
                                queryLocation(text: textFieldText)
                            }
                            .textContentType(.location)
                            .foregroundColor(erroneousLocation ? .red : Color(.lightText))
                            .disableAutocorrection(true)
                            .autocapitalization(UITextAutocapitalizationType.words)
                            .padding([.trailing, .top, .bottom])
                        }
                        .background(
                            Rectangle()
                                .foregroundColor(Color.init(.sRGB, white: 1, opacity: 0.1))
                                .cornerRadius(12)
                        )
                        .transition(.scale)
                    }
                    
                    Spacer()
                    
                    Button(action: { // gps locate button
                        if locationPermissionGranted {
                            // set map to current location
                            let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                            lightImpactFeedbackGenerator.impactOccurred()
                            
                            if usingCurrentLocation {
                                // if in tracking state, switch to custom state
                                #warning("maybe leave all state change savig to later")
                                withAnimation {
                                    usingCurrentLocation = false
                                }
                            } else {
                                timer?.invalidate() // prevent a timer that is still trying to calculate a location from proceeding
                                awaitingLocationUpdate = true
                                // at this point, we already know whether location permissions were granted
                                // just ask athanmanager to ask for a location update and capture it
                                AthanManager.shared.attemptSingleLocationUpdate { capturedLocationSettings in
                                    print("CALLBACK")
                                    let settings = capturedLocationSettings ?? AthanManager.shared.locationSettings.copy() as! LocationSettings
                                    textFieldText = settings.locationName
                                    boundCoordinate = settings.locationCoordinate // change map location
                                    unboundCoordinate = settings.locationCoordinate // change stored location
                                    timeZone = settings.timeZone
                                    // Adopt the new country too. Without this the code stayed on
                                    // whatever the user had typed before, so switching from a
                                    // manual Karachi back to Current Location in New York saved
                                    // countryCode "PK" and left the method on Karachi instead of
                                    // moving to ISNA.
                                    if let cc = settings.countryCode, !cc.isEmpty {
                                        detectedCountryCode = cc
                                    } else {
                                        detectedCountryCode = nil
                                        lookUpCountryCode(for: settings.locationCoordinate)
                                    }
                                    updateLocalizedPrayer(coord: unboundCoordinate)
                                    
                                    awaitingLocationUpdate = false
                                    withAnimation {
                                        usingCurrentLocation = true
                                    }
                                }
                            }
                        } else if AthanManager.shared.locationManager.authorizationStatus == .notDetermined {
                            // Never asked yet (common on a fresh Mac launch) — request permission,
                            // which shows the system prompt instead of leaving a dead button.
                            AthanManager.shared.requestLocationPermission()
                        } else {
                            // Previously denied/restricted — send the user to Settings.
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsURL) {
                                UIApplication.shared.open(settingsURL, completionHandler: { _ in })
                            }
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            if usingCurrentLocation {
                                Image(systemName: "hand.draw.fill")
                                    .foregroundColor(.gray)
                                    .padding([.leading])
                                
                                Text(Strings.setLocationManually)
                                    .foregroundColor(.gray)
                                    .bold()
                                    .padding([.top, .bottom, .trailing])
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    .minimumScaleFactor(0.01)
                            } else {
                                if awaitingLocationUpdate {
                                    ActivityIndicator(isAnimating: .constant(true), style: .white)
                                } else {
                                    Image(systemName: locationPermissionGranted ? "location.fill" : "location.slash.fill")
                                        .foregroundColor(.white)
                                        .padding([.leading])
                                }
                                
                                Text(Strings.useCurrentLocation)
                                    .foregroundColor(.white)
                                    .bold()
                                    .padding([.top, .bottom, .trailing])
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    .minimumScaleFactor(0.01)
                            }
                            
                            Spacer()
                        }
                        .background(
                            Rectangle()
                                .foregroundColor(usingCurrentLocation ? .white : .blue)
                                .cornerRadius(12)
                        )
                    })
                    .buttonStyle(ScalingButtonStyle())
                    .opacity(usingCurrentLocation || locationPermissionGranted ? 1 : 0.85) // still tappable — taps request permission
                    
                    Spacer()
                    
                    Text(locationPermissionGranted ? Strings.doesNotCollectData : Strings.locationDisabledAndDoesNotCollectData
                    )
                    .font(.subheadline)
                    .foregroundColor(Color(.lightText))
                    .padding([.bottom])

                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
                        Button(action: { // DONE BUTTON
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()

                            if !erroneousLocation {
                                AthanManager.shared.locationSettings = LocationSettings(locationName: textFieldText, coord: unboundCoordinate, timeZone: timeZone, useCurrentLocation: usingCurrentLocation, countryCode: detectedCountryCode)
                                AthanManager.shared.reloadSettingsAndNotifications()

                                if IntroSetupFlags.hasCompletedCalculationSetup {
                                    // returning user editing location — keep the travel auto-suggest popup
                                    // The user just set this location by hand, so the
                                    // recommendation applies even if we have already
                                    // evaluated this country passively at launch.
                                    AthanManager.shared.autoUpdateMethodIfNeeded(for: detectedCountryCode,
                                                                                 userChangedLocation: true)
                                } else {
                                    // first-time setup — apply the settings shown in the recommended card
                                    let ps = AthanManager.shared.prayerSettings
                                    ps.calculationMethod = cardMethod
                                    ps.madhab = cardMadhab
                                    ps.latitudeRule = cardLatRule
                                    AthanManager.shared.prayerSettings = ps
                                    IntroSetupFlags.hasCompletedCalculationSetup = true
                                    AthanManager.shared.reloadSettingsAndNotifications()
                                }
                            }

                            withAnimation {
                                self.parentSession = .Main
                            }
                        }) {
                            Text(Strings.done)
                                .foregroundColor(Color(.lightText))
                                .font(Font.body.weight(.bold))
                        }
                        .accessibilityIdentifier("locationDoneButton")
                    }
                }
                .padding()
                .padding([.leading, .trailing, .bottom])
                // On wide windows (Mac / regular size class) cap the content width and center it
                // instead of stretching the map + controls edge-to-edge.
                .frame(maxWidth: hSizeClass == .regular ? 640 : .infinity)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear { syncCardFromRecommendation() }
        .onChange(of: detectedCountryCode) { _ in syncCardFromRecommendation() }
        .sheet(isPresented: $showingSettingsEditor, onDismiss: {
            userEditedCalcSettings = true
            syncCardFromManager()
        }) {
            IntroSettingsView(parentSession: .constant(.Location), isSheet: true)
                .preferredColorScheme(.dark)
        }
    }

    /// Resolve just the country for a coordinate, for the Current Location path where
    /// CoreLocation handed us a fix without one. Deliberately touches nothing but
    /// `detectedCountryCode` — the name, coordinate and time zone are already set.
    func lookUpCountryCode(for coord: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, _ in
            guard let code = placemarks?.first?.isoCountryCode, !code.isEmpty else { return }
            DispatchQueue.main.async { detectedCountryCode = code }
        }
    }

    func queryLocation(text: String) {
        // reverse geocode address
        geocoder.geocodeAddressString(text) { (placemarks, error) in
            defer { awaitingUserSearchLookup = false }
            guard let placemark = placemarks?.first, let coord = placemark.location?.coordinate, error == nil else {
                erroneousLocation = true
                print("failed to understand address, \(error!)")
                return
            }
            
            print("GEOCODER - found coordinate")
            boundCoordinate = coord // tell map to change
            unboundCoordinate = coord
            detectedCountryCode = placemark.isoCountryCode
            if placemark.timeZone == nil { print("!!! BAD: time zone for placemark nil")}
            timeZone = placemark.timeZone ?? timeZone //

            updateLocalizedPrayer(coord: unboundCoordinate)
        }
    }
    
    func queryAndSaveCoordinate(coord: CLLocationCoordinate2D) {
        // reverse geocode coordinate
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { (placemarks, error) in
            defer { awaitingUserSearchLookup = false }
            guard let placemark = placemarks?.first, error == nil else {
                //                erroneousLocation = true
//                if !usingCurrentLocation { return } // in case user switches back to not using current location
                erroneousLocation = false // no need to show error for a coordinate. leave it as is
                detectedCountryCode = nil // unknown country when geocoding fails
                textFieldText = String(format: "%.2f°, %.2f°",
                                       coord.latitude,
                                       coord.longitude)
                unboundCoordinate = coord
                // timeZone = timeZone -> if user gives coordinates without being able to lookup, trust that their device timezone is correct
                timeZone = Calendar.current.timeZone
                updateLocalizedPrayer(coord: unboundCoordinate)
                //                boundCoordinate = coord; #warning("telling map to change coordinate might make it cause a second call to this function")
                return
            }
            
            print("GEOCODER - found placemark")
            detectedCountryCode = placemark.isoCountryCode
            //            let city = placemark.locality
            //            let district = placemark.subAdministrativeArea
            //            let state = placemark.administrativeArea
            //            let country = placemark.isoCountryCode
            //            if let name = placemark.name {
            //                textFieldText = name // hoping this will handle most localization cases
            //            } else
            if Locale.preferredLanguages.first?.hasPrefix("en") ?? false, // at least in english, we can be sure that "city, state" will format correctly
               let city = placemark.locality,
               let state = placemark.administrativeArea {
                if city == state {
                    textFieldText = city // some nationalities seem to define their locality and admin area as the same things
                } else {
                    textFieldText = "\(city), \(state)"
                }
            } else if let city = placemark.locality {
                textFieldText = city
            } else if let state = placemark.administrativeArea {
                textFieldText = state
            } else {
                textFieldText = String(format: "%.2f°, %.2f°",
                                       coord.latitude,
                                       coord.longitude)
            }
            unboundCoordinate = coord
            if placemark.timeZone == nil { print("!!! BAD: time zone for placemark nil")}
            timeZone = placemark.timeZone ?? timeZone //
            updateLocalizedPrayer(coord: unboundCoordinate)
        }
    }
}

@available(iOS 13.0.0, *)
struct LocationSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(.sRGB, red: Double(25)/255 , green: Double(78)/255 , blue: Double(135)/255, opacity: 1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            LocationSettingsView(parentSession: .constant(.Location), locationPermissionGranted: .constant(true))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}

/// Compact summary of the calculation settings recommended for the chosen
/// location, with an "Edit" disclosure that opens the full editor as a sheet.
private struct RecommendedSettingsCard: View {
    let method: CalculationMethod
    let madhab: Madhab
    let latRule: HighLatitudeRule
    var edited: Bool
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(edited
                     ? NSLocalizedString("your_settings_title", value: "Your settings", comment: "Onboarding card title after editing")
                     : NSLocalizedString("recommended_settings_title", value: "Recommended for your location", comment: "Onboarding recommended-settings card title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onEdit()
                }) {
                    HStack(spacing: 2) {
                        Text(NSLocalizedString("edit", value: "Edit", comment: "Edit button"))
                        Image(systemName: "chevron.right").font(.caption.weight(.bold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(.lightText))
                }
                .accessibilityIdentifier("editRecommendedSettings")
            }
            .padding(.bottom, 10)

            row(Strings.calculationMethod, method.localizedString())
            divider
            row(Strings.madhab, madhab.stringValue())
            divider
            row(Strings.highLatitudeRuleTitle, latRule.localizedString())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.12)).frame(height: 0.5).padding(.vertical, 9)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(Color(.lightText))
            Spacer()
            Text(value).foregroundColor(.white).fontWeight(.semibold)
                .lineLimit(1).minimumScaleFactor(0.6).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

