//
//  ViewController.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 04/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var aMap: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.aMap.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true);
        
        // Create and initialize a search request object.
        let request = MKLocalSearchRequest();
        request.naturalLanguageQuery = "restaurant";
        request.region = self.aMap.region;
        
        // Create and initialize a search object.
        let search = MKLocalSearch(request: request);
        
        
        // Start the search and display the results as annotations on the map.
        search.start(completionHandler: {response,error in
            var placemarks = [MKAnnotation]();
            for item in (response?.mapItems)! {
                placemarks.append(item.placemark);
            }
            self.aMap.removeAnnotations(self.aMap.annotations);
            self.aMap.showAnnotations(placemarks, animated: false);
            })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

