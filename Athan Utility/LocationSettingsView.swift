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
struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

@available(iOS 13.0.0, *)
struct LocationSettingsView: View, Equatable {
    
    static func == (lhs: LocationSettingsView, rhs: LocationSettingsView) -> Bool {
        // << return yes on view properties which identifies that the
        // view is equal and should not be refreshed (ie. `body` is not rebuilt)
        return (lhs.usingCurrentLocation == rhs.usingCurrentLocation && rhs.templocationSettings.locationName == lhs.templocationSettings.locationName
                    && lhs.locationPermissionGranted == rhs.locationPermissionGranted && rhs.unboundCoordinate.latitude == lhs.unboundCoordinate.latitude)
    }
    
    #warning("make sure updating this value changes earlier settings?")
    
    // start text field as a copy of the location settings loc name
    @State var textFieldText: String = "\(AthanManager.shared.locationSettings.locationName)"
    
    // state shared with map view. save coordinate, usingcurrent, and name on exit
    @State var boundCoordinate = AthanManager.shared.locationSettings.locationCoordinate
    @State var unboundCoordinate = AthanManager.shared.locationSettings.locationCoordinate
    @State var usingCurrentLocation = AthanManager.shared.locationSettings.useCurrentLocation
    
    @State var templocationSettings: LocationSettings = AthanManager.shared.locationSettings.copy() as! LocationSettings
    @Binding var parentSession: CurrentView // used to trigger transition back
    
    @Binding var locationPermissionGranted: Bool
    
    @State var awaitingLocationUpdate = false
    // is the currently inputted location string understandable
    @State var erroneousLocation = false
    
    @State var timer: Timer?
    
    let geocoder = CLGeocoder()
    var mapView: MapView?
        
    @State var localizedCurrentPrayer: Prayer = ObservableAthanManager.shared.currentPrayer
    @State var appearanceCopy = ObservableAthanManager.shared.appearance
    var setup: Int = {
        UITextField.appearance().clearButtonMode = .always
        UITextField.appearance().tintColor = .white
        AthanManager.shared.requestLocationPermission()
        return 0
    }()
    
    func updateLocalizedPrayer(coord: CLLocationCoordinate2D) {
        let times = AthanManager.shared.calculateTimes(referenceDate: Date(), customCoordinate: unboundCoordinate)
        localizedCurrentPrayer = times?.currentPrayer() ?? .isha
    }
    
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
                                    print("creating timer")
                                    unboundCoordinate = loc
                                    updateLocalizedPrayer(coord: unboundCoordinate)
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
                    
                    
                    // Input text field for location
                    if !usingCurrentLocation {
                        HStack {
                            Text(Strings.locationColon)
                                .foregroundColor(erroneousLocation ? .red : .white)
                                .bold()
                                .padding([.leading])
                            TextField(Strings.locationName, text: $textFieldText) { isEditing in
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
                                            queryAndSaveCoordinate(coord: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                            return
                                        }
                                    }
                                }
                                queryLocation(text: textFieldText)
                            }
                            .textContentType(.location)
                            .foregroundColor(erroneousLocation ? .red : Color(.lightText))
                            .disableAutocorrection(true)
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
                                //                            AthanDefaults.useCurrentLocation = false
                                #warning("maybe leave all state change savig to later")
                                withAnimation {
                                    usingCurrentLocation = false
                                }
                            } else {
                                timer?.invalidate() // prevent a timer that is still trying to calculate a location from proceeding
                                //                            AthanDefaults.useCurrentLocation = true
                                awaitingLocationUpdate = true
                                // at this point, we already know whether location permissions were granted
                                // just ask athanmanager to ask for a location update and capture it
                                AthanManager.shared.attemptSingleLocationUpdate { capturedLocationSettings in
                                    print("CALLBACK")
                                    let settings = capturedLocationSettings ?? AthanManager.shared.locationSettings.copy() as! LocationSettings
                                    textFieldText = settings.locationName
                                    boundCoordinate = settings.locationCoordinate // change map location
                                    unboundCoordinate = settings.locationCoordinate // change stored location
                                    updateLocalizedPrayer(coord: unboundCoordinate)
                                    
                                    awaitingLocationUpdate = false
                                    withAnimation {
                                        usingCurrentLocation = true
                                    }
                                }
                            }
                        } else {
                            // open settings for locations
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsURL) {
                                UIApplication.shared.open(settingsURL, completionHandler: { _ in })
                            }
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            if usingCurrentLocation {
                                Image(systemName: "mappin")
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
                    .opacity(usingCurrentLocation || locationPermissionGranted ? 1 : 0.2)
                    
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
                            
                            // save settings if we don't have erroneous input
                            if !erroneousLocation {
                                AthanManager.shared.locationSettings = LocationSettings(locationName: textFieldText, coord: unboundCoordinate, useCurrentLocation: usingCurrentLocation)
                                
                                // force athan manager to recalculate
                                AthanManager.shared.considerRecalculations(force: true)
                                print("new settings: \(textFieldText), \(unboundCoordinate.latitude), \(unboundCoordinate.longitude)")
                            }
                            
                            withAnimation {
                                self.parentSession = .Main
                            }
                        }) {
                            Text(Strings.done)
                                .foregroundColor(Color(.lightText))
                                .font(Font.body.weight(.bold))
                        }
                    }
                }
                .padding()
                .padding([.leading, .trailing, .bottom])
            }
        }
    }
    
    func queryLocation(text: String) {
        // reverse geocode address
        geocoder.geocodeAddressString(text) { (placemarks, error) in
            guard let coord = placemarks?.first?.location?.coordinate, error == nil else {
                erroneousLocation = true
                print("failed to understand address, \(error!)")
                return
            }
            
            print("GEOCODER - found coordinate")
            boundCoordinate = coord // tell map to change
            unboundCoordinate = coord
            updateLocalizedPrayer(coord: unboundCoordinate)
        }
    }
    
    func queryAndSaveCoordinate(coord: CLLocationCoordinate2D) {
        // reverse geocode coordinate
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { (placemarks, error) in
            guard let placemark = placemarks?.first, error == nil else {
                //                erroneousLocation = true
                if !usingCurrentLocation { return } // in case user switches back to not using current location
                erroneousLocation = false // no need to show error for a coordinate. leave it as is
                textFieldText = String(format: "%.2f°, %.2f°",
                                       coord.latitude,
                                       coord.longitude)
                unboundCoordinate = coord
                updateLocalizedPrayer(coord: unboundCoordinate)
                //                boundCoordinate = coord; #warning("telling map to change coordinate might make it cause a second call to this function")
                return
            }
            
            print("GEOCODER - found placemark")
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
                textFieldText = "\(city), \(state)"
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

