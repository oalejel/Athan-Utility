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
struct MapView: UIViewRepresentable, Equatable {
    static func == (lhs: MapView, rhs: MapView) -> Bool {
        let res = lhs.center.latitude == rhs.center.latitude && lhs.center.longitude == rhs.center.longitude
            && lhs.usingCurrentLocation == rhs.usingCurrentLocation
//        if res == false {
//            print("MAP NOT EQUAL")
//        }
        return res
    }
    
    typealias UIViewType = MKMapView
    let mapView = MKMapView()
    
    @Binding var center: CLLocationCoordinate2D // used by parent to command change in map center
    @Binding var usingCurrentLocation: Bool
    var regionChangedClosure: ((CLLocationCoordinate2D) -> ())? // used to tell view when we change the state ourselves
    
    init(center: Binding<CLLocationCoordinate2D>, usingCurrentLocation: Binding<Bool>, regionChangedClosure: ((CLLocationCoordinate2D) -> ())?) {
        self._center = center
        self._usingCurrentLocation = usingCurrentLocation
        self.regionChangedClosure = regionChangedClosure
    }

    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
//        uiView.setCenter(center, animated: true)
//        print("> map updateUIView called")
        if abs(uiView.centerCoordinate.latitude - center.latitude) > 0.00001 &&
            abs(uiView.centerCoordinate.longitude - center.longitude) > 0.00001 {
            uiView.setCenter(center, animated: true)
            uiView.setRegion(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)), animated: true)
        }
        
        uiView.isUserInteractionEnabled = !usingCurrentLocation
    }

    func makeCoordinator() -> MapView.Coordinator {
        Coordinator(self)
    }

    // Coordinator
    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        
        private let coordinatedView: MapView
        var pan: UIPanGestureRecognizer!
        var pinch: UIPinchGestureRecognizer!
        var tap: UITapGestureRecognizer!

        init(_ mapView: MapView) {
            self.coordinatedView = mapView
            super.init()
            pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
            pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
            tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
            tap.numberOfTapsRequired = 2
            pan.delegate = self
            pinch.delegate = self
            tap.delegate = self
            mapView.mapView.addGestureRecognizer(pan)
            mapView.mapView.addGestureRecognizer(pinch)
            mapView.mapView.addGestureRecognizer(tap)
            
            
        }
        
        var gestureFlag = false
        // call this to tell user that we have updated the region manually
        func endedMapGesture() {
            gestureFlag = true
        }
        
        @objc
        func panGesture(gestureRecognizer: UIPanGestureRecognizer) {
            // pan gets preferential treatment, not excluding pinch from being ended
            if pan.state == .ended && !(pan.state == .began || pan.state == .changed) {
                print(pan.state.rawValue, pinch.state.rawValue)
                print("> PAN ENDED LAST")
                endedMapGesture()
            }
        }
        
        @objc
        func pinchGesture(gestureRecognizer: UIPanGestureRecognizer) {
            if pinch.state == .ended && !(pan.state == .began || pan.state == .changed || pan.state == .ended) {
                print(pan.state.rawValue, pinch.state.rawValue)
                print("> PINCH ENDED LAST")
                endedMapGesture()
            }
        }
        
        @objc
        func tapGesture(gestureRecognizer: UIPanGestureRecognizer) {
            if tap.state == .ended {
                print("> TAP ENDED")
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { tap in
                    self.endedMapGesture() // call this after 0.2 seconds to let map animate to place
                }
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // if we are animating to position, publish that we already updated the coordinate
            if coordinatedView.usingCurrentLocation && !(mapView.userLocation.coordinate.latitude == 0 && mapView.userLocation.coordinate.longitude == 0) {
//                coordinatedView.center = mapView.userLocation.coordinate
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            print(">> region did change")
            if gestureFlag {
                gestureFlag = false
                print("> MARKED REGION CHANGED")
//                coordinatedView.center = mapView.centerCoordinate
                DispatchQueue.main.async {
                    self.coordinatedView.regionChangedClosure?(mapView.centerCoordinate)
                }
            } else if self.coordinatedView.usingCurrentLocation {
                print("> CHANGED WHEN USING CURRENT LOC")
//                DispatchQueue.main.async {
//                    self.coordinatedView.regionChangedClosure?(mapView.centerCoordinate)
//                }
            }
        }
        
        
//
////            // ignore region changes that dont change center coordinate
////            if abs(mapView.centerCoordinate.latitude - mapView.center.latitude) > 0.00001 &&
////                abs(mapView.centerCoordinate.longitude - mapView.center.longitude) > 0.00001 {
////                print("center coord did change with region")
////                DispatchQueue.main.async {
////                    self.centeredLocation = mapView.centerCoordinate
////    //                self.useCurrentLocation = false // switch back to manual mode
////                }
////            }
//        }

    }
}
