//
//  RunPoint.swift
//  MyRunApp
//
//  Created by Jody Abney on 5/20/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import UIKit
import MapKit

enum RunPointType {
    case beginning
    case ending
}

class RunPoint: NSObject, MKAnnotation {
    var runPointType: RunPointType
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var timestamp: Date
    
    init(type: RunPointType, coordinate: CLLocationCoordinate2D, timestamp: Date) {
        self.runPointType = type
        self.coordinate = coordinate
        self.timestamp = timestamp
        
        switch runPointType {
        case .beginning:
            self.title = "Run Started Here"
        case .ending:
            self.title = "Run Ended Here"
        }
        
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .full
        self.subtitle = df.string(from: timestamp)

    }
    
}
