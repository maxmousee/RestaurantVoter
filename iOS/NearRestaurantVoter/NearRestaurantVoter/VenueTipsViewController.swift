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
import UserNotifications

/** Shows tips related to a venue. */
class VenueTipsViewController: UITableViewController {
    var venueId: String?
    var session: Session!
    var uid: String?
    var isAnonymous = true
    var tips: [JSONParameters]?
    
    
    @IBOutlet weak var voteButton: UIBarButtonItem!
    
    // firebase database
    var ref: FIRDatabaseReference!
    
    
    @IBAction func voteForRestaurant(_ sender: Any) {
        
        if (userAlreadyVotedToday()) {
            let alertController = UIAlertController(title: "User already voted today",
                                                    message: "You can't vote twice a day", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: {
                (action) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            signInAnonymously();
            if(shouldCleanUpUserWeeklyVotes()) {
                deleteUserWeeklyVotes();
            }
            postVoteForRestaurant(theVenueId: venueId!);
            addWeeklyVoteForUser(theVenueId: venueId!);
            addReminderNotificationIfVoted();
        }
    }
    
    func addReminderNotificationIfVoted() {
        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day: components.day, hour: 13, minute: 0)
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert,.sound,.badge],
                completionHandler: { (granted,error) in
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
                    let content = UNMutableNotificationContent()
                    content.title = "Restaurant Voting Ended"
                    content.body = "Just a reminder to check where you will eat today"
                    content.sound = UNNotificationSound.default()
                    let request = UNNotificationRequest(identifier: "textNotification", content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    UNUserNotificationCenter.current().add(request) {(error) in
                        if let error = error {
                            print("Uh oh! We had an error posting the local notification: \(error)")
                        } else {
                            print("Local notification posted");
                        }
                    }
            })
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    func configureFirDatabase() {
        ref = FIRDatabase.database().reference()
    }
    
    func deleteUserWeeklyVotes() {
        //TODO delete all user's votes this week
    }
    
    func signInAnonymously() {
        FIRAuth.auth()?.signInAnonymously() { (user, error) in
            if (error == nil) {
                self.isAnonymous = user!.isAnonymous  // true
                self.uid = user!.uid
            } else {
                print(error ?? "Unknown error to sign in");
            }
        }
    }
    
    func userAlreadyVotedToday() -> Bool {
        let voteTimestamp = UserDefaults.standard.double(forKey: Constants.Defaults.lastVoteTimestamp);
        if (voteTimestamp == 0) {
            return false;
        }
        if (Date(timeIntervalSince1970: (voteTimestamp + Constants.NumValues.secondsInADay)).timeIntervalSince1970 > Date().timeIntervalSince1970) {
            return true;
        }
        return false;
    }
    
    func shouldCleanUpUserWeeklyVotes() -> Bool {
        let voteTimestamp = UserDefaults.standard.double(forKey: Constants.Defaults.lastVoteTimestamp);
        if (voteTimestamp == 0) {
            return false;
        }
        if (Date(timeIntervalSince1970: (voteTimestamp + Constants.NumValues.secondsInAWeek)).timeIntervalSince1970 > Date().timeIntervalSince1970) {
            return true;
        }
        return false;
    }
    
    func postVoteForRestaurant(theVenueId: String) {
        //let key = ref.child(Constants.VotesFields.users).childByAutoId().key
        //read current vote count
        
        ref.child(Constants.VotesFields.venues).child(theVenueId).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get votes value
            let value = snapshot.value as? NSDictionary
            var currentVotes = value?[Constants.VotesFields.voteCount] as? Int ?? 0
            // ...
            currentVotes += 1;
            let vote = [Constants.VotesFields.voteCount: currentVotes,
                        Constants.VotesFields.locationName: self.title ?? "Unknown Venue"] as [String : Any]
            let childUpdates = ["/\(Constants.VotesFields.venues)/\(theVenueId)/": vote]
            self.ref.updateChildValues(childUpdates)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func addWeeklyVoteForUser(theVenueId: String) {
        ref.child(Constants.VotesFields.users).child(theVenueId).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get votes value
            let value = snapshot.value as? NSDictionary
            var currentVotes = value?[Constants.VotesFields.voteCount] as? Int ?? 0
            // ...
            currentVotes += 1;
            let vote = [Constants.VotesFields.voteCount: currentVotes,
                        Constants.VotesFields.locationId: theVenueId] as [String : Any]
            let childUpdates = ["/\(Constants.VotesFields.users)/\(self.uid)/": vote]
            self.ref.updateChildValues(childUpdates)
            
        }) { (error) in
            print(error.localizedDescription)
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
