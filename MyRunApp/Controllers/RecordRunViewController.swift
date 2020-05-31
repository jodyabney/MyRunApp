//
//  RecordRunViewController.swift
//  MyRunApp
//
//  Created by Jody Abney on 5/18/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import UIKit
import MapKit

class RecordRunViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startButton: RoundButton!
    @IBOutlet weak var stopButton: RoundButton!
    @IBOutlet weak var runDistanceLabel: UILabel!
    @IBOutlet weak var runDurationLabel: UILabel!
    @IBOutlet weak var selectedDistanceUnit: UISegmentedControl!
    
    
    //MARK: - Properties
    
    private var runMode = RunMode.notStarted {
        didSet {
            if runMode == .completed {
                startButton.setTitle("Start Run", for: .normal)
            } else {
                startButton.setTitle("Stop Run", for: .normal)
            }
        }
    }
    
    //    private var buttonTitle = "Start Run"
    
    private var run: Run?
    
    private var timer: Timer?
    private var duration: Measurement<UnitDuration>?
    private var distance: Measurement<UnitLength>?
    private var locations: [Location?] = []
    
    // track if the run path already has a start pin
    private var startLocationAnnotated = false
    
    //MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the mapview delegate
        mapView.delegate = self
        // check the privacy location settings
        checkLocationAuthStatus()
        // show the Start button and hide the Stop button
        stopButton.isHidden = true
        startButton.isHidden = false
        // update the display
        updateDisplay()
    }
    
    //MARK: - Instance Methods
    
    private func startRun() {
        // clear any existing map overlays and annotations
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        // set initial values for a new run and clear any existing run locations
        duration = Measurement(value: 0.0, unit: UnitDuration.seconds)
        distance = Measurement(value: 0.0, unit: UnitLength.meters)
        locations.removeAll()
        
        // set up the run
        run = Run(distance: distance, duration: duration, timestamp: Date(), locations: locations)
        // run does not have a start pin set yet
        startLocationAnnotated = false
        // start tracking user location
        LocationService.instance.locationManager.startUpdatingLocation()
        // set a timer to periodically handle the display using update run data
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.eachSecond()
        }
    }
    
    private func stopRun() {
        // stop tracking the run
        LocationService.instance.locationManager.stopUpdatingLocation()
        // set run distance
        run!.setRunDistance()
        // set run duration
        run!.setRunDuration()
        // update the display labels
        updateDisplay()
        
    }
    
    func eachSecond() {
        // store the current run duration
        run!.setRunDuration()
        // store the current run distance
        run!.setRunDistance()
        // display the run path
        updateRunPath()
        // update the display labels
        updateDisplay()
    }
    
    private func updateRunPath() {
        // ensure there are at leas two coordinate entries so a path can be drawn
        guard let runCoordinates = run!.getRunCoordinates(), runCoordinates.count > 1 else { return }
        // display the run on the map
        let runPolyLine = MKPolyline(coordinates: runCoordinates, count: runCoordinates.count)
        self.mapView.addOverlay(runPolyLine)
        
        // set up the start and end points to display on the map
        if !startLocationAnnotated {
            let startLoc = run!.locations.first!
            setupAnnotation(type: .beginning,
                            coordinates: (runCoordinates.first)!,
                            timestamp: startLoc!.timestamp)
            startLocationAnnotated = true
        }
    }
    
    private func updateDisplay() {
        // handle updating display if run is not started
        guard (run?.distance?.value) != nil else {
            
            // set distance label prior to run starting
            let initialDistance = Measurement(value: 0.0, unit: UnitLength.miles)
            
            switch selectedDistanceUnit.selectedSegmentIndex {
            case 0: // miles
                distance = initialDistance.converted(to: .miles)
            case 1: // kilometers
                distance = initialDistance.converted(to: .kilometers)
            default:
                return
            }
            let distanceValue = String(format: "%.2f", distance!.value)
            let distanceUnit = distance!.unit.symbol
            runDistanceLabel.text = distanceValue + " " + distanceUnit
            
            return
        }
        
        // handle updating distance label once run starts
        switch selectedDistanceUnit.selectedSegmentIndex {
        case 0: // miles
            distance = run!.distance!.converted(to: .miles)
        case 1: // kilometers
            distance = run!.distance!.converted(to: .kilometers)
        default:
            return
        }
        let distanceValue = String(format: "%.2f", distance!.value)
        let distanceUnit = distance!.unit.symbol
        runDistanceLabel.text = distanceValue + " " + distanceUnit
        
        // update the run duration display
        if let durationInSec = run?.duration?.converted(to: .seconds) {
            // display seconds until 60 seconds or greater
            if durationInSec.value < 60 {
                let durationValue = durationInSec.value
                let durationUnit = durationInSec.unit.symbol
                runDurationLabel.text = String(format: "%.0f", durationValue) + " " + durationUnit
            } else {
                // display minutes if greater than 60 seconds
                let duration = durationInSec.converted(to: .minutes)
                let durationValue = duration.value
                let durationUnit = duration.unit.symbol
                runDurationLabel.text = String(format: "%.0f", durationValue) + " " + durationUnit
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // set up the display for the run path
        let runRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        runRenderer.strokeColor = .systemBlue
        runRenderer.lineWidth = 5
        runRenderer.alpha = 0.85
        return runRenderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // set up a map pin
        if let annotation = annotation as? RunPoint {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.calloutOffset = CGPoint(x: -8, y: -3)
            
            // set the pin color based on if the pin is the start or end of the run
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
    
    func setupAnnotation(type: RunPointType, coordinates: CLLocationCoordinate2D, timestamp: Date) {
        let runAnnotation = RunPoint(type: type, coordinate: coordinates, timestamp: timestamp)
        mapView.addAnnotation(runAnnotation)
    }
    
    
    //MARK: - IBActions
    
    @IBAction func startButtonPressed(_ sender: RoundButton) {
        switch runMode {
        case .completed:
            runMode = RunMode.started
            startRun()
        case .started:
            runMode = RunMode.completed
            stopRun()
        case .notStarted:
            runMode = RunMode.started
            startRun()
        }
        // hide the Start button and show the Stop button
        startButton.isHidden = true
        stopButton.isHidden = false
        
    }
    
    @IBAction func stopButtonPressed(_ sender: RoundButton) {
        // reset the Start button and Stop button
        startButton.isHidden = false
        stopButton.isHidden = true
        // stop the run
        runMode = RunMode.completed
        stopRun()
    }
    
    @IBAction func distanceUnitSelector(_ sender: UISegmentedControl) {
        // update the display if the distance unit changes
        updateDisplay()
    }
    
}

//MARK: - MapView Delegate

extension RecordRunViewController: MKMapViewDelegate {
    
    // check for location authorization
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            print("location authorized")
        } else {
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
            print("location authorization requested")
        }
        // display the user location and set the custom user location delegate
        self.mapView.showsUserLocation = true
        LocationService.instance.customUserLocDelegate = self
        
    }
    
    // center the map on the user location
    func centerMapOnUserLocation(coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates,
                                        latitudinalMeters: 250,
                                        longitudinalMeters: 250)
        self.mapView.setRegion(region, animated: true)
    }
}


//MARK: - Custom User Location Delegate

extension RecordRunViewController: CustomUserLocDelegate {
    
    func userLocationUpdated(location: CLLocation) {
        // center on the user location
        centerMapOnUserLocation(coordinates: location.coordinate)
        
        // add user location to locationList
        let runnerLocation = Location(coordinates: location.coordinate, timestamp: Date())
        run?.locations.append(runnerLocation)
    }
}


//MARK: - Navigation

extension RecordRunViewController {
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        if let runDisplayVC = segue.destination as? DisplayRunViewController {
            
            // Pass the selected object to the new view controller.
            runDisplayVC.run = run
        }
    }
}

