//
//  MapView.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 12/23/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import MapKit
import SwiftUI

@available(iOS 13.0.0, *)
struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView

    @Binding var center: CLLocationCoordinate2D // used to command the ui to change state
    @Binding var usingCurrentLocation: Bool
    var regionChangedClosure: ((CLLocationCoordinate2D) -> ())? // used to tell view when we change the state ourselves
    
    init(center: Binding<CLLocationCoordinate2D>, usingCurrentLocation: Binding<Bool>, regionChangedClosure: ((CLLocationCoordinate2D) -> ())?) {
        self._center = center
        self._usingCurrentLocation = usingCurrentLocation
        self.regionChangedClosure = regionChangedClosure
    }

    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
//        uiView.setCenter(center, animated: true)
        if abs(uiView.centerCoordinate.latitude - center.latitude) > 0.00001 &&
            abs(uiView.centerCoordinate.longitude - center.longitude) > 0.00001 {
            uiView.setCenter(center, animated: true)
            uiView.setRegion(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)), animated: true)
        }
        uiView.isUserInteractionEnabled = !usingCurrentLocation
    }

    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(self)
    }

    // Coordinator
    final class Coordinator: NSObject, MKMapViewDelegate {
        private let mapView: MapView

        init(_ mapView: MapView) {
            self.mapView = mapView
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            self.mapView.center = mapView.centerCoordinate
            DispatchQueue.main.async {
                self.mapView.regionChangedClosure?(mapView.centerCoordinate)
            }
            
//            // ignore region changes that dont change center coordinate
//            if abs(mapView.centerCoordinate.latitude - mapView.center.latitude) > 0.00001 &&
//                abs(mapView.centerCoordinate.longitude - mapView.center.longitude) > 0.00001 {
//                print("center coord did change with region")
//                DispatchQueue.main.async {
//                    self.centeredLocation = mapView.centerCoordinate
//    //                self.useCurrentLocation = false // switch back to manual mode
//                }
//            }

        }
    }
}


@available(iOS 13.0.0, *)
final class OldMapView : NSObject, UIViewRepresentable, MKMapViewDelegate {
    typealias UIViewType = MKMapView
    let mapView = MKMapView()
    
    // map sends over new location
    //
    
    @Binding var centeredLocation: CLLocationCoordinate2D
    @Binding var useCurrentLocation: Bool
    
    init(centeredLocation: Binding<CLLocationCoordinate2D>, useCurrentLocation: Binding<Bool>) {
        self._centeredLocation = centeredLocation
        self._useCurrentLocation = useCurrentLocation
        super.init()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = self
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // avoid cenering when regionDidChange is called
        if abs(uiView.centerCoordinate.latitude - centeredLocation.latitude) > 0.00001 &&
            abs(uiView.centerCoordinate.longitude - centeredLocation.longitude) > 0.00001 {
            uiView.setCenter(centeredLocation, animated: true)
            uiView.setRegion(MKCoordinateRegion(center: centeredLocation, span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)), animated: true)
        }
        uiView.isUserInteractionEnabled = !useCurrentLocation
    }
    
    // MARK: - Map View Delegate
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        print("will")
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // ignore region changes that dont change center coordinate
        if abs(mapView.centerCoordinate.latitude - centeredLocation.latitude) > 0.00001 &&
            abs(mapView.centerCoordinate.longitude - centeredLocation.longitude) > 0.00001 {
            print("center coord did change with region")
            DispatchQueue.main.async {
                self.centeredLocation = mapView.centerCoordinate
//                self.useCurrentLocation = false // switch back to manual mode
            }
        }
    }
}
