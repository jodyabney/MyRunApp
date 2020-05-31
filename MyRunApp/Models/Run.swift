//
//  Run.swift
//  MyRunApp
//
//  Created by Jody Abney on 5/18/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

enum RunMode {
    case started
    case completed
    case notStarted
}

struct Run {
    var distance: Measurement<UnitLength>?
    var duration: Measurement<UnitDuration>?
    var timestamp: Date?
    var locations: [Location?]
    
    func getRunCoordinates() -> [CLLocationCoordinate2D]? {
        guard locations.count > 0 else {
            return nil
        }
        
        var runCoordinates: [CLLocationCoordinate2D] = []
        for location in locations {
            runCoordinates.append(location!.coordinates)
        }
        
        return runCoordinates
    }
    
    mutating func setRunDistance() {
        guard locations.count > 1 else { return }
        
        var totalDistance = 0.0
        
        for i in 0..<locations.count - 1 {
            let startLoc = CLLocation(latitude: (locations[i]?.coordinates.latitude)!,
                                      longitude: (locations[i]?.coordinates.longitude)!)
            let nextLoc = CLLocation(latitude: (locations[i + 1]?.coordinates.latitude)!,
                                     longitude: (locations[i + 1]?.coordinates.longitude)!)
            totalDistance += startLoc.distance(from: nextLoc)
        }
        
        self.distance = Measurement(value: totalDistance, unit: UnitLength.meters)
    }
    
    mutating func setRunDuration() {
        guard locations.count > 1, let firstLoc = locations.first!, let endLoc = locations.last! else { return }
        
        let runDuration = endLoc.timestamp.timeIntervalSinceReferenceDate - firstLoc.timestamp.timeIntervalSinceReferenceDate
        
        self.duration = Measurement(value: runDuration, unit: UnitDuration.seconds)
    }    
}



