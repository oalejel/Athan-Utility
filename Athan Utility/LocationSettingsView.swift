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
final class MapView : NSObject, UIViewRepresentable, MKMapViewDelegate {
    typealias UIViewType = MKMapView
    
    @Binding var centeredLocation: CLLocationCoordinate2D
    
    init(centeredLocation: Binding<CLLocationCoordinate2D>) {
        self._centeredLocation = centeredLocation
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = self
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // avoid cenering when regionDidChange is called
        uiView.delegate = self
        if uiView.centerCoordinate.latitude != centeredLocation.latitude &&
            uiView.centerCoordinate.longitude != centeredLocation.longitude {
            uiView.setCenter(centeredLocation, animated: true)
            uiView.setRegion(MKCoordinateRegion(center: centeredLocation, span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)), animated: true)
        }
    }
    
    // MARK: - Map View Delegate
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // ignore region changes that dont change center coordinate
        if mapView.centerCoordinate.latitude != centeredLocation.latitude &&
            mapView.centerCoordinate.longitude != centeredLocation.longitude {
            print("center coord did change with region")
            DispatchQueue.main.async {
                self.centeredLocation = mapView.centerCoordinate
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct LocationSettingsView: View {
    
    #warning("make sure updating this value changes earlier settings?")
    
    
    // start text field as location settings loc name
    @State var textFieldText: String = LocationSettings.shared.locationName
    @State var mapCoordinate: CLLocationCoordinate2D = LocationSettings.shared.locationCoordinate
    
    @State var templocationSettings: LocationSettings = LocationSettings.shared.copy() as! LocationSettings
    @Binding var parentSession: CurrentView // used to trigger transition back
    
    @State var usingCurrentLocation = false
    // is the currently inputted location string understandable
    @State var erroneousLocation = false
    
    let geocoder = CLGeocoder()
    
    var setup: Int = {
        UITextField.appearance().clearButtonMode = .always
        UITextField.appearance().tintColor = .white
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
                    MapView(centeredLocation: $mapCoordinate)
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
                                Text("\(mapCoordinate.latitude, specifier: "%.2f")˚, \(mapCoordinate.longitude, specifier: "%.2f")˚")
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

                HStack {
//                    Image(systemName: "location.fill")
//                        .padding([.leading])
//                        .foregroundColor(.white)
                    Text("Location:")
                        .foregroundColor(.white)
                        .bold()
                        .padding([.leading])
                    TextField("Location Name", text: $textFieldText) { (didChange) in
                        erroneousLocation = false // reset potential error
                    } onCommit: {
                        queryLocation(text: textFieldText)
                    }
                    .foregroundColor(erroneousLocation ? .red : Color(.lightText))
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disableAutocorrection(true)
                    .padding([.trailing, .top, .bottom])
                }
                .background(
                    Rectangle()
                        .foregroundColor(Color.init(.sRGB, white: 1, opacity: 0.1))
                        .cornerRadius(12)
                )
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        if AthanManager.shared.locationPermissionsGranted {
                            
                        }
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Image(systemName: AthanManager.shared.locationPermissionsGranted ? "location.fill" : "location.slash.fill")
                            .foregroundColor(.white)
                            .padding([.leading])
    //                    Spacer()
                        Text("Set to GPS Location")
                            .foregroundColor(.white)
                            .bold()
                            .padding([.top, .bottom, .trailing])
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.01)
                            
                        Spacer()
                    }
                    .background(
                        Rectangle()
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    )
                })
                .buttonStyle(ScalingButtonStyle())
                .opacity(AthanManager.shared.locationPermissionsGranted ? 1 : 0.2)

                Spacer()
                
                Text("Location services are disabled, and can be adjusted in Settings. Athan Utility does not collect user data.")
                    .font(.subheadline)
                    .foregroundColor(Color(.lightText))
                    .padding(4)
//                    .opacity()
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    
                    Button(action: {
                        // tap vibration
                        let lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                        lightImpactFeedbackGenerator.impactOccurred()
                        withAnimation {
                            self.parentSession = .Main
                        }
                    }) {
                        Text("Done")
                            .foregroundColor(Color(.lightText))
                            .font(Font.body.weight(.bold))
                    }
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
            mapCoordinate = coord
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
