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

typealias JSONParameters = [String: AnyObject]

class ExploreViewController: UITableViewController,CLLocationManagerDelegate,
SearchTableViewControllerDelegate {
    
    var locationManager = CLLocationManager();
    var currentCLLocation: CLLocation!;
    var foursquareSession: Session!;
    var locationStatus = "Not Started";
    var venueItems : [[String: AnyObject]]?
    
    /** Number formatter for rating. */
    let numberFormatter = NumberFormatter()
    
    var searchController: UISearchController!
    var resultsTableViewController: SearchTableViewController!
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        //print("locations = \(locValue.latitude) \(locValue.longitude)")
        currentCLLocation = manager.location;
        searchNearbyRestaurants();
    }
    
    func getUserLocation() {
        // Ask for Authorisation from the User.
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.delegate = self
        
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        } else if status == CLAuthorizationStatus.authorizedWhenInUse
            || status == CLAuthorizationStatus.authorizedAlways {
            self.locationManager.startUpdatingLocation()
        } else {
            showNoPermissionsAlert()
        }
    }
    
    func showNoPermissionsAlert() {
        let alertController = UIAlertController(title: "No permission",
                                                message: "In order to work, app needs your location", preferredStyle: .alert)
        let openSettings = UIAlertAction(title: "Open settings", style: .default, handler: {
            (action) -> Void in
            let URL = Foundation.URL(string: UIApplicationOpenSettingsURLString)
            UIApplication.shared.openURL(URL!)
            self.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(openSettings)
        present(alertController, animated: true, completion: nil)
    }
    
    func showErrorAlert(_ error: NSError) {
        let alertController = UIAlertController(title: "Error",
                                                message:error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: {
            (action) -> Void in
            self.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
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
        
        let task = self.foursquareSession.venues.explore(parameters) {
            (result) -> Void in
            if self.venueItems != nil {
                return
            }
            if !Thread.isMainThread {
                fatalError("!!!")
            }
            
            if let response = result.response {
                if let groups = response["groups"] as? [[String: AnyObject]]  {
                    var venues = [[String: AnyObject]]()
                    for group in groups {
                        if let items = group["items"] as? [[String: AnyObject]] {
                            venues += items
                        }
                    }
                    
                    self.venueItems = venues
                }
                self.tableView.reloadData()
            } else if let error = result.error , !result.isCancelled() {
                self.showErrorAlert(error)
            }
        }
        task.start()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let venueItems = self.venueItems {
            return venueItems.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "venueCell", for: indexPath)
            as! VenueTableViewCell
        let item = self.venueItems![(indexPath as NSIndexPath).row] as JSONParameters!
        self.configureCellWithItem(cell, item: item!)
        return cell
    }
    
    
    func configureCellWithItem(_ cell:VenueTableViewCell, item: JSONParameters) {
        if let venueInfo = item["venue"] as? JSONParameters {
            cell.venueNameLabel.text = venueInfo["name"] as? String
            if let rating = venueInfo["rating"] as? CGFloat {
                let number = NSNumber(value: Float(rating))
                cell.venueRatingLabel.text = numberFormatter.string(from: number)
            }
        }
        if let tips = item["tips"] as? [JSONParameters], let tip = tips.first {
            cell.venueCommentLabel.text = tip["text"] as? String
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! VenueTableViewCell
        let tips = self.venueItems![(indexPath as NSIndexPath).row]["tips"] as? [JSONParameters]
        guard let tip = tips?.first, let user = tip["user"] as? JSONParameters,
            let photo = user["photo"] as? JSONParameters else {
                return
        }
        let URL = photoURLFromJSONObject(photo)
        if let imageData = foursquareSession.cachedImageDataForURL(URL)  {
            cell.userPhotoImageView.image = UIImage(data: imageData)
        } else {
            cell.userPhotoImageView.image = nil
            foursquareSession.downloadImageAtURL(URL) {
                (imageData, error) -> Void in
                let cell = tableView.cellForRow(at: indexPath) as? VenueTableViewCell
                if let cell = cell, let imageData = imageData {
                    let image = UIImage(data: imageData)
                    cell.userPhotoImageView.image = image
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let venue = venueItems![(indexPath as NSIndexPath).row]["venue"] as! JSONParameters
        openVenue(venue)
    }
    
    func searchTableViewController(_ controller: SearchTableViewController, didSelectVenue venue:JSONParameters) {
        openVenue(venue)
    }
    
    func openVenue(_ venue: JSONParameters) {
        let viewController = Storyboard.create("venueDetails") as! VenueTipsViewController
        viewController.venueId = venue["id"] as? String
        viewController.session = foursquareSession
        viewController.title = venue["name"] as? String
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func photoURLFromJSONObject(_ photo: JSONParameters) -> URL {
        let prefix = photo["prefix"] as! String
        let suffix = photo["suffix"] as! String
        let URLString = prefix + "100x100" + suffix
        let URL = Foundation.URL(string: URLString)
        return URL!
    }
    
    func sessionWillPresentAuthorizationViewController(_ controller: AuthorizationViewController) {
        print("Will present authorization view controller.")
    }
    
    func sessionWillDismissAuthorizationViewController(_ controller: AuthorizationViewController) {
        print("Will disimiss authorization view controller.")
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
        self.numberFormatter.numberStyle = .decimal
        self.resultsTableViewController = Storyboard.create("venueSearch") as! SearchTableViewController
        self.resultsTableViewController.session = foursquareSession
        self.resultsTableViewController.delegate = self
        self.searchController = UISearchController(searchResultsController: resultsTableViewController)
        self.searchController.searchResultsUpdater = resultsTableViewController
        self.definesPresentationContext = true
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
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

class Storyboard: UIStoryboard {
    class func create(_ name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: name)
    }
}


