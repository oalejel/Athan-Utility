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
struct LocationSettingsView: View {
    
    #warning("make sure updating this value changes earlier settings?")
    
    // start text field as a copy of the location settings loc name
    @State var textFieldText: String = "\(LocationSettings.shared.locationName)"
    
    // state shared with map view 
    @State var boundCoordinate = LocationSettings.shared.locationCoordinate
    @State var unboundCoordinate = LocationSettings.shared.locationCoordinate
    @State var usingCurrentLocation = AthanDefaults.useCurrentLocation
    
    @State var templocationSettings: LocationSettings = LocationSettings.shared.copy() as! LocationSettings
    @Binding var parentSession: CurrentView // used to trigger transition back
    
    @State var awaitingLocationUpdate = false
    // is the currently inputted location string understandable
    @State var erroneousLocation = false
    
    @State var timer: Timer?
    
    let geocoder = CLGeocoder()
    var mapView: MapView?
    
    var setup: Int = {
        UITextField.appearance().clearButtonMode = .always
        UITextField.appearance().tintColor = .white
        AthanManager.shared.requestLocationPermission()
        return 0
    }()
    
    var body: some View {
        
        GeometryReader { g in
            VStack(alignment: .leading) {
                Text("Set Location")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding(0)
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.01)
                
                ZStack {
                    MapView(center: $boundCoordinate, usingCurrentLocation: $usingCurrentLocation) { loc in
                        
                        // if the source of the update is not a manual input,
                        // we don't want to set the location name
                        print(loc)
                        if !usingCurrentLocation {
                            print("creating timer")
                            unboundCoordinate = loc
                            timer?.invalidate()
                            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { t in
                                queryCoordinate(coord: loc)
                            }
                        }
                    }
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

                // Input text field for location
                if !usingCurrentLocation {
                    HStack {
                        Text("Location:")
                            .foregroundColor(erroneousLocation ? .red : .white)
                            .bold()
                            .padding([.leading])
                        TextField("Location Name", text: $textFieldText) { (didChange) in
                            erroneousLocation = false // reset potential error
                        } onCommit: {
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
                
                // gps locate button
                
                Button(action: {
                    if AthanManager.shared.locationPermissionsGranted {
                        // set map to current location
                        let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        lightImpactFeedbackGenerator.impactOccurred()
                        
                        if usingCurrentLocation {
                            // if in tracking state, switch to custom state
                            AthanDefaults.useCurrentLocation = false
                            #warning("maybe leave all state change savig to later")
                            withAnimation {
                                usingCurrentLocation = false
                            }
                        } else {
                            AthanDefaults.useCurrentLocation = true
                            awaitingLocationUpdate = true
                            // at this point, we already know whether location permissions were granted
                            // just ask athanmanager to ask for a location update and capture it
                            AthanManager.shared.attemptSingleLocationUpdate { capturedLocationSettings in
                                let settings = capturedLocationSettings ?? AthanManager.shared.locationSettings.copy() as! LocationSettings
                                textFieldText = settings.locationName
                                boundCoordinate = settings.locationCoordinate
                                
                                awaitingLocationUpdate = false
                                withAnimation {
                                    usingCurrentLocation = true
                                }
                            }
                        }
                    }
                }, label: {
                    HStack {
                        Spacer()
                        if usingCurrentLocation {
                            Image(systemName: "mappin")
                                .foregroundColor(.gray)
                                .padding([.leading])
                            
                            Text("Set Location Manually")
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
                                Image(systemName: AthanManager.shared.locationPermissionsGranted ? "location.fill" : "location.slash.fill")
                                    .foregroundColor(.white)
                                    .padding([.leading])
                            }
                            
                            Text("Use Current Location")
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
                .opacity(AthanManager.shared.locationPermissionsGranted ? 1 : 0.2)

                Spacer()
            
                Text(AthanManager.shared.locationPermissionsGranted ? "Athan Utility does not collect user data." : "Location services are disabled, and can be adjusted in Settings. Athan Utility does not collect user data."
                )
                    .font(.subheadline)
                    .foregroundColor(Color(.lightText))
                .padding([.bottom])

                Spacer()
                HStack(alignment: .center) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        
                        // save settings if we don't have erroneous input
                        if !erroneousLocation {
                            AthanDefaults.useCurrentLocation = usingCurrentLocation
                            AthanManager.shared.locationSettings = LocationSettings(locationName: textFieldText, coord: unboundCoordinate)
                            
                            // force athan manager to recalculate 
                            AthanManager.shared.considerRecalculations(isNewLocation: true)
                            print("new settings: \(AthanManager.shared.locationSettings)")
                        }
                        
                        withAnimation {
                            self.parentSession = .Main
                        }
                    }) {
                        Text("Done")
                            .foregroundColor(Color(.lightText))
                            .font(Font.body.weight(.bold))
                    }
                    Spacer()
                }
            }
            .padding()
            .padding([.leading, .trailing, .bottom])
        }
    }
    
    func queryLocation(text: String) {
        // reverse geocode location
        geocoder.geocodeAddressString(text) { (placemarks, error) in
            guard let coord = placemarks?.first?.location?.coordinate, error == nil else {
                erroneousLocation = true
                print("failed to understand address, \(error!)")
                return
            }
            
            print("GEOCODER - found coordinate")
            boundCoordinate = coord
        }
    }
    
    func queryCoordinate(coord: CLLocationCoordinate2D) {
        // reverse geocode coordinate
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { (placemarks, error) in
            
            guard let placemark = placemarks?.first, error == nil else {
                erroneousLocation = true
                print("failed to understand address, \(error!)")
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
            if let city = placemark.locality {
                textFieldText = city
            } else if let state = placemark.administrativeArea {
                textFieldText = state
            } else {
                textFieldText = String(format: "%.2f°, %.2f°",
                                       coord.latitude,
                                       coord.longitude)
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct LocationSettingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.blue]), startPoint: .topLeading, endPoint: .init(x: 2, y: 2))
                .edgesIgnoringSafeArea(.all)
            LocationSettingsView(parentSession: .constant(.Location))
        }
        .environmentObject(ObservableAthanManager.shared)
        .previewDevice("iPhone Xs")
    }
}

