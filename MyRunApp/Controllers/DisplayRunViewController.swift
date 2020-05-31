//
//  DisplayRunViewController.swift
//  MyRunApp
//
//  Created by Jody Abney on 5/28/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import UIKit
import MapKit
import MessageUI

class DisplayRunViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceUnitSegmentedControl: UISegmentedControl!
    @IBOutlet weak var runDistanceLabel: UILabel!
    @IBOutlet weak var runDurationLabel: UILabel!
    
    
    //MARK: - Properties
    
    var run: Run!
    
    
    //MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        // update the run path
        updateRunPath()
        
        // set the run duration
        run.setRunDuration()
        
        // set the run distance
        run.setRunDistance()
        
        // update the duration and distance labels
        updateDisplay()

    }
    
    //MARK: - Instance Methods
    
    private func updateRunPath() {
        
        let runCoordinates = run.getRunCoordinates()
        let runPolyLine = MKPolyline(coordinates: runCoordinates!, count: runCoordinates!.count)
        // display the run on the map
        self.mapView.addOverlay(runPolyLine)
        self.mapView.setVisibleMapRect(runPolyLine.boundingMapRect,
                                       edgePadding: UIEdgeInsets(top: 250, left: 50,
                                                                 bottom: 50, right: 50),
                                       animated: true)
        // set up the start and end points to display on the map
        let startLoc = run!.locations.first!
        setupAnnotation(type: .beginning,
                        coordinates: (runCoordinates?.first)!,
                        timestamp: startLoc!.timestamp)
        let endLoc = run!.locations.first!
        setupAnnotation(type: .ending,
                        coordinates: (runCoordinates?.last)!,
                        timestamp: endLoc!.timestamp)
    }
    
    private func updateDisplay() {
        
        var distance: Measurement<UnitLength>?
        
        switch distanceUnitSegmentedControl.selectedSegmentIndex {
        case 0:
            distance = run.distance?.converted(to: .miles)
        case 1:
            distance = run.distance?.converted(to: .kilometers)
        default:
            return
        }
        
        let distanceValue = String(format: "%.2f", distance!.value)
        let distanceUnit = distance!.unit.symbol
        
        runDistanceLabel.text = distanceValue + " " + distanceUnit
        
        // update the run duration display
        if let durationInSec = run?.duration?.converted(to: .seconds) {
            if durationInSec.value < 60 {
                let durationValue = durationInSec.value
                let durationUnit = durationInSec.unit.symbol
                runDurationLabel.text = String(format: "%.0f", durationValue) + " " + durationUnit
            } else {
                let duration = durationInSec.converted(to: .minutes)
                let durationValue = duration.value
                let durationUnit = duration.unit.symbol
                runDurationLabel.text = String(format: "%.0f", durationValue) + " " + durationUnit
            }
        }
    }
    
    //MARK: - IBActions
    
    @IBAction func distanceUnitSegmentedControlledTapped(_ sender: UISegmentedControl) {
        
        updateDisplay()
    }
    

    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        
        // set up activity view controller
        if let image = view.takeScreenshot() {
            let message = "Here's a screenshot of my run"
            let activityController = UIActivityViewController(activityItems: [ message, image ],
                                                              applicationActivities: nil)
            // present the view controller
            self.present(activityController, animated: true, completion: nil)
        }
    }
}

//MARK: - MapViewDelegate

extension DisplayRunViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? RunPoint {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.calloutOffset = CGPoint(x: -8, y: -3)
            
            switch annotation.runPointType {
            case .beginning:
                view.pinTintColor = .systemGreen
            case .ending:
                view.pinTintColor = .systemRed
            }
            
            return view
        } else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let runRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        runRenderer.strokeColor = .systemBlue
        runRenderer.lineWidth = 5
        runRenderer.alpha = 0.85
        
        return runRenderer
    }
    
    func setupAnnotation(type: RunPointType, coordinates: CLLocationCoordinate2D, timestamp: Date) {
        let runAnnotation = RunPoint(type: type, coordinate: coordinates, timestamp: timestamp)
        mapView.addAnnotation(runAnnotation)
    }
}
