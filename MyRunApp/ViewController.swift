//
//  ViewController.swift
//  MyRunApp
//
//  Created by Jody Abney on 5/18/20.
//  Copyright © 2020 AbneyAnalytics. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var runButton: RoundButton!
    @IBOutlet weak var runDistanceLabel: UILabel!
    @IBOutlet weak var selectedDistanceUnit: UISegmentedControl!
    
    //MARK: - Properties
    
    private var runMode = RunMode.stopped {
        didSet {
            if runMode == .stopped {
                runButton.setTitle("Start Run", for: .normal)
            } else {
                runButton.setTitle("Stop Run", for: .normal)
            }
        }
    }
    
    private var buttonTitle = "Start Run"
    
    private var run: Run?
    
    private var seconds = 0
    private var timer: Timer?
    private var duration: Measurement<UnitDuration>?
    private var distance: Measurement<UnitLength>?
    private var locations: [Location?] = []
    
    //MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        checkLocationAuthStatus()
        runDistanceLabel.isHidden = true
    }
    
    //MARK: - Instance Methods
    
    private func startRun() {
        // set initial values for a new run
        duration = Measurement(value: 0.0, unit: UnitDuration.seconds)
        distance = Measurement(value: 0.0, unit: UnitLength.meters)
        locations.removeAll()
        
        run = Run(distance: distance, duration: duration, timestamp: Date(), locations: locations)
        
        updateDisplay()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.eachSecond()
        }
        
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        runDistanceLabel.isHidden = true
        
        LocationService.instance.locationManager.startUpdatingLocation()
    }
    
    private func stopRun() {
        // stop tracking the run
        LocationService.instance.locationManager.stopUpdatingLocation()
        // build the run
        let runCoordinates = run?.getRunCoordinates()
        let runPolyLine = MKPolyline(coordinates: runCoordinates!, count: runCoordinates!.count)
        // display the run on the map
        self.mapView.addOverlay(runPolyLine)
        self.mapView.setVisibleMapRect(runPolyLine.boundingMapRect,
                                       edgePadding: UIEdgeInsets(top: 200, left: 50,
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
        
        // set the run duration
        duration = run?.getRunDuration()
        run?.duration = duration
        
        // set the run distance
        distance = run?.getRunDistance()
        run?.distance = distance
        
        updateDisplay()
        
    }
    
    func eachSecond() {
        seconds += 1
        updateDisplay()
    }
    
    private func updateDisplay() {
//        let formattedDistance = FormatDisplay.distance(distance!)
//        let formattedTime = FormatDisplay.time(seconds)
//        let formattedPace = FormatDisplay.pace(distance: distance!,
//                                               seconds: seconds,
//                                               outputUnit: UnitSpeed.minutesPerMile)
        
        if runMode == .stopped {
            
            runDistanceLabel.isHidden = false
            
            switch selectedDistanceUnit.selectedSegmentIndex {
            case 0:
                distance = run!.distance!.converted(to: .miles)
            case 1:
                distance = run!.distance!.converted(to: .kilometers)
            default:
                return
            }
            
            let distanceValue = String(format: "%.2f", distance!.value)
            let distanceUnit = distance!.unit.symbol
            runDistanceLabel.text = distanceValue + " " + distanceUnit
        } else {
            runDistanceLabel.isHidden = true
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
    
    
    //MARK: - IBActions
    
    @IBAction func runButtonPressed(_ sender: RoundButton) {
        switch runMode {
        case .stopped:
            runMode = RunMode.started
            startRun()
        case .started:
            runMode = RunMode.stopped
            stopRun()
        }
    }
    
    @IBAction func distanceUnitSelector(_ sender: UISegmentedControl) {

        updateDisplay()
    }
    
}


//MARK: - MapView Delegate

extension ViewController: MKMapViewDelegate {
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            print("location authorized")
            self.mapView.showsUserLocation = true
            LocationService.instance.customUserLocDelegate = self
        } else {
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
            print("location authorization requested")
        }
    }
    
    func centerMapOnUserLocation(coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates,
                                        latitudinalMeters: 250,
                                        longitudinalMeters: 250)
        self.mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? RunPoint {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.calloutOffset = CGPoint(x: -8, y: -3)
            
            switch annotation.runPointType {
            case .beginning:
                view.pinTintColor = .green
            case .ending:
                view.pinTintColor = .red
            }
            
            return view
        } else {
            return nil
        }
    }
}


//MARK: - Custom User Location Delegate

extension ViewController: CustomUserLocDelegate {
    
    func userLocationUpdated(location: CLLocation) {
        centerMapOnUserLocation(coordinates: location.coordinate)
        
        // add location to locationList
        let runnerLocation = Location(coordinates: location.coordinate, timestamp: Date())
        run?.locations.append(runnerLocation)
    }
}
