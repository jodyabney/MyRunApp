//
//  LocationService.swift
//  Park.ly
//
//  Created by Jody Abney on 5/18/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import Foundation
import CoreLocation

protocol CustomUserLocDelegate {
    func userLocationUpdated(location: CLLocation)
}

class LocationService: NSObject, CLLocationManagerDelegate {
    
    static let instance = LocationService()
    
    var customUserLocDelegate: CustomUserLocDelegate?
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.activityType = .fitness
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location?.coordinate
        
        if customUserLocDelegate != nil {
            customUserLocDelegate?.userLocationUpdated(location: locations.first!)
        }
    }
}


