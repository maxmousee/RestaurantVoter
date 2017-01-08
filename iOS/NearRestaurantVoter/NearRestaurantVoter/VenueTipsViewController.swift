//
//  VenueTipsViewController.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 06/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import Firebase
import QuadratTouch

/** Shows tips related to a venue. */
class VenueTipsViewController: UITableViewController {
    var venueId: String?
    var session: Session!
    var tips: [JSONParameters]?
    
    // firebase database
    var ref: FIRDatabaseReference!

    
    @IBAction func voteForRestaurant(_ sender: Any) {
        createUser();
        
        postVoteForRestaurant(venueId: venueId!);
    }
    
    func configureFirDatabase() {
        ref = FIRDatabase.database().reference()
    }
    
    func createUser() {
        FIRAuth.auth()?.createUser(withEmail: "howanopab@30wave.com", password: "Lalala@1234") { (user, error) in
            // ...
        }
    }
    
    func postVoteForRestaurant(venueId: String) {
        ref.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var post = currentData.value as? [String : AnyObject], let uid = FIRAuth.auth()?.currentUser?.uid {
                var vote: Dictionary<String, Bool>
                vote = post[Constants.VotesFields.vote] as? [String : Bool] ?? [:]
                var voteCount = post[Constants.VotesFields.voteCount] as? Int ?? 0
                if let _ = vote[uid] {
                    // Unstar the post and remove self from stars
                    voteCount -= 1
                    vote.removeValue(forKey: uid)
                } else {
                    // Star the post and add self to stars
                    voteCount += 1
                    vote[uid] = true
                }
                post[Constants.VotesFields.voteCount] = voteCount as AnyObject?
                post[Constants.VotesFields.vote] = vote as AnyObject?
                
                // Set value and report transaction success
                currentData.value = post
                print("DONE");
                return FIRTransactionResult.success(withValue: currentData)
            }
            return FIRTransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
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
        configureFirDatabase();
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
