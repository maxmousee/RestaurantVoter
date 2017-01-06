//
//  ViewController.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 04/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import UIKit
import MapKit
import QuadratTouch
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager();
    var currentCLLocation: CLLocation!;
    var foursquareSession: Session!;
    var locationStatus = "Not Started";
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        //print("locations = \(locValue.latitude) \(locValue.longitude)")
        currentCLLocation = manager.location;
        searchNearbyRestaurants();
    }
    
    func getUserLocation() {
        // Ask for Authorisation from the User.
        self.locationManager.requestWhenInUseAuthorization()
        
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func setupFoursquareSession() -> Session {
        let client = Client(clientID:       "2OMA3WBEWYITHKPHSHUWRX43PTXRLEEJKJZZKVWZ0AU2EWEM",
                            clientSecret:   "30SIYXA43ZN14UQ3XTVFVFV1S50YNSM4VBSHX4DHEWG5YKKM",
                            redirectURL:    "NearRestaurantVoter://foursquare")
        let configuration = Configuration(client:client)
        Session.setupSharedSessionWithConfiguration(configuration)
        let foursquareSession = Session.sharedSession();
        foursquareSession.logger = ConsoleLogger();
        return foursquareSession;
    }
    
    func searchNearbyRestaurants() {
        guard let location = currentCLLocation else {
            return
        }
        
        var parameters = [Parameter.query:"food"]
        parameters += location.parameters();
        
        print(parameters);
        let searchTask = foursquareSession.venues.search(parameters) {
            (result) -> Void in
            if let response = result.response {
                //print(result)
                //print(response)
                //print(response["venues"] ?? "none")
                //self.venues = response["venues"] as [JSONParameters]?
                //self.tableView.reloadData()
            }
        }
        searchTask.start()
    }
    
    // authorization status
    private func locationManager(manager: CLLocationManager!,
                         didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status {
        case CLAuthorizationStatus.restricted:
            locationStatus = "Restricted Access to location"
        case CLAuthorizationStatus.denied:
            locationStatus = "User denied access to location"
        case CLAuthorizationStatus.notDetermined:
            locationStatus = "Status not determined"
        default:
            locationStatus = "Allowed to location Access"
            shouldIAllow = true
        }
        
        if (shouldIAllow == true) {
            NSLog("Location to Allowed")
            // Start location services
            locationManager.startUpdatingLocation()
        } else {
            NSLog("Denied access: \(locationStatus)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        foursquareSession = setupFoursquareSession();
        getUserLocation();
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        // Dispose of any resources that can be recreated.
    }


}

extension CLLocation {
    func parameters() -> Parameters {
        let ll      = "\(self.coordinate.latitude),\(self.coordinate.longitude)"
        let llAcc   = "\(self.horizontalAccuracy)"
        let alt     = "\(self.altitude)"
        let altAcc  = "\(self.verticalAccuracy)"
        let parameters = [
            Parameter.ll:ll,
            Parameter.llAcc:llAcc,
            Parameter.alt:alt,
            Parameter.altAcc:altAcc
        ]
        return parameters
    }
}


