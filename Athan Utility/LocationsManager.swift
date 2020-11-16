//
//  LocationsManager.swift
//  Athan Utility
//
//  Created by Omar Al-Ejel on 11/15/20.
//  Copyright © 2020 Omar Alejel. All rights reserved.
//

import CoreLocation

class LocationsManager: CLLocationManagerDelegate {
    static var shared = LocationsManager()
    
    //location services data provider
    let coreManager = CLLocationManager()
    var lastAuthStatus = CLAuthorizationStatus.notDetermined
    
    init() {
        coreManager.delegate = self
        coreManager.desiredAccuracy = kCLLocationAccuracyKilometer
        coreManager.requestWhenInUseAuthorization() // move elsewhere
        
    }
    
    // MARK: - CLLocationManagerDelegate
    
    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if lastAuthStatus == .denied || lastAuthStatus == .notDetermined {
            if shouldSyncLocation && (manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways) {
                coreManager.startUpdatingLocation() // user has decided to share location, so start process of getting data
                lastAuthStatus = manager.authorizationStatus
                return
            }
        }
        
        // try to load data for the current location if current data is out of date
        if !hasDataForNextMonth() && gpsStrings != nil {
            fetchMonthsJSONDataForCurrentLocation { (success) in
                self.notifyWidget()
            }
        } else if manager.authorizationStatus != .notDetermined { // ONLY if we are not in the notDetermined stage can we be sure that we have probably failed
            self.notifyWidget()
        }
        lastAuthStatus = manager.authorizationStatus
    }
    
    // in case user initially prevents location updates and decides to switch back
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if lastAuthStatus == .denied || lastAuthStatus == .notDetermined {
            if shouldSyncLocation && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                coreManager.startUpdatingLocation() // user has decided to share location, so start process of getting data
                lastAuthStatus = status
                return
            }
        }
        
        // try to load data for the current location if current data is out of date
        if !hasDataForNextMonth() && gpsStrings != nil {
            fetchMonthsJSONDataForCurrentLocation { (success) in
                self.notifyWidget()
            }
        } else if status != .notDetermined { // ONLY if we are not in the notDetermined stage can we be sure that we have probably failed
            self.notifyWidget()
        }
        lastAuthStatus = status
    }
    
    // tell our delegate that the heading has been updated (qibla view controller)
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingDelegate?.newHeading(newHeading)
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LOCATION MANAGER ERROR: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coreManager.stopUpdatingLocation() //change if stopping without getting reliable info
        
        // need this since location managers send multiple updates even after being told to stop updating
        if ignoreLocationUpdates == true {
            // hide swift spinner in case we are blocking the screen
            delegate?.hideLoadingView?()
            return
        }
        ignoreLocationUpdates = true
        
        CLGeocoder().reverseGeocodeLocation(locations.first!, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) -> Void in
            if let x = error {
                print(x)
            } else {
                if placemarks?.count > 0 {
                    let placemark = placemarks![0]
                    
                    // if we should not update, then abort fetching
                    if !self.shouldRequestJSONForLocation(locality: placemark.locality, subAdminArea: placemark.subAdministrativeArea, state: placemark.administrativeArea, countryCode: placemark.isoCountryCode) {
                        // we know that the location we already have is correct
//                        self.delegate?.syncLocation = true
                        self.delegate?.locationIsSynced = true
                        self.delegate?.hideLoadingView?()
                        
                        // tell widgets / requester that we have success, since there is no need for an update
                        self.notifyWidget()
                        return
                    }
                    
                    // update our recorded location
                    self.gpsStrings = GPSStrings(currentCityString: placemark.locality,
                                                 currentDistrictString: placemark.subAdministrativeArea,
                                                 currentStateString: placemark.administrativeArea,
                                                 currentCountryString: placemark.isoCountryCode)
                    self.coordinate = placemark.location?.coordinate
                    
                    //update our location string used to make queries and display in UI
                    self.readableLocationString = self.readableAddressString()
                    
                
                }
            }
        })
    }
}

