//
//  VenueTipsViewController.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 06/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import Foundation
import UIKit

import QuadratTouch

/** Shows tips related to a venue. */
class VenueTipsViewController: UITableViewController {
    var venueId: String?
    var session: Session!
    var tips: [JSONParameters]?
    
    @IBAction func voteForRestaurant(_ sender: Any) {
        print("Vote for this restaurant %s", venueId);
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
        let task = self.session.venues.get(self.venueId!) {
            (result) -> Void in
            if let response = result.response {
                if let venue = response["venue"] as? JSONParameters,
                    let tips = venue["tips"] as? JSONParameters {
                    var tipItems = [JSONParameters]()
                    if let groups = tips["groups"] as? [JSONParameters] {
                        for group in groups {
                            if let item = group["items"] as? [JSONParameters] {
                                tipItems += item
                            }
                        }
                    }
                    self.tips = tipItems
                }
            } else {
                // Show error.
            }
            self.tableView.reloadData()
        }
        task.start()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tips = self.tips {
            return tips.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let tip = self.tips![(indexPath as NSIndexPath).row]
        cell.textLabel?.text = tip["text"] as? String
        return cell
    }
}
