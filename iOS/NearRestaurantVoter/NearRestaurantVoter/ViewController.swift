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
    var location: CLLocation!;
    var locationStatus = "Not Started";
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        //print("locations = \(locValue.latitude) \(locValue.longitude)")
        location = manager.location;
    }
    
    func getUserLocation() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
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
        
        return Session.sharedSession();
    }
    
    func searchNearbyRestaurants() {
        let foursquareSession = setupFoursquareSession();
        var parameters = [Parameter.query:"Restaurants"]
        //let locationDict = ["ll": String(format:"%.8f,%.8f", self.location.coordinate.latitude,self.location.coordinate.longitude)]
        let locationDict = ["ll": String(format:"%.2f,%.2f", -30.06,-51.16)]
        parameters += locationDict
        print(parameters);
        let searchTask = foursquareSession.venues.search(parameters) {
            (result) -> Void in
            if let response = result.response {
                print(result)
                print(response)
                print(response["venues"] ?? "none")
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
        getUserLocation();
        searchNearbyRestaurants();
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        // Dispose of any resources that can be recreated.
    }


}

