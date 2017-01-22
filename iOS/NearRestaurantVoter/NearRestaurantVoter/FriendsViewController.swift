//
//  FriendsViewController.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 06/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import UIKit
import Firebase

/** Shows list of friends votes. */
class FriendsViewController: UITableViewController {
        
    var venues: [FIRDataSnapshot]! = []
    var ref: FIRDatabaseReference!
    fileprivate var _refHandle: FIRDatabaseHandle!
    
    var storageRef: FIRStorageReference!
    var remoteConfig: FIRRemoteConfig!
    var maxMsgLength = 30;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDatabase()
        configureStorage()
        configureRemoteConfig()

    }
    
    deinit {
        self.ref.child(Constants.VotesFields.venues).removeObserver(withHandle: _refHandle)
    }
    
    
    func configureDatabase() {
        
        ref = getReferenceVoteFIRDB()
        // Listen for new messages in the Firebase database
        _refHandle = self.ref.child(Constants.VotesFields.venues).observe(.childAdded, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.venues.append(snapshot)
            strongSelf.tableView.insertRows(at: [IndexPath(row: strongSelf.venues.count-1, section: 0)], with: .automatic)
        })
    }
    
    func configureRemoteConfig() {
        remoteConfig = FIRRemoteConfig.remoteConfig()
        // Create Remote Config Setting to enable developer mode.
        // Fetching configs from the server is normally limited to 5 requests per hour.
        // Enabling developer mode allows many more requests to be made per hour, so developers
        // can test different config values during development.
        let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings!
    }

    
    func configureStorage() {
        let storageUrl = FIRApp.defaultApp()?.options.storageBucket
        storageRef = FIRStorage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    func fetchConfig() {
        var expirationDuration: Double = 3600
        // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
        // the server.
        if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
            expirationDuration = 0
        }
        
        // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
        // fetched and cached config would be considered expired because it would have been fetched
        // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
        // throttling is in progress. The default expiration duration is 43200 (12 hours).
        remoteConfig.fetch(withExpirationDuration: expirationDuration) { (status, error) in
            if (status == .success) {
                print("Config fetched!")
                self.remoteConfig.activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(error)")
            }
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= maxMsgLength; // Bool
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let theVenues = self.venues {
            return theVenues.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendTableViewCell

        // Unpack message from Firebase DataSnapshot
        let snapshot: FIRDataSnapshot! = self.venues[indexPath.row]
        let value = snapshot.value as? NSDictionary
        let currentVotes = value?[Constants.VotesFields.voteCount] as? Int ?? 0
        let currentVenueName = value?[Constants.VotesFields.locationName] as? String ?? "Unknown Venue"
        
        if (currentVotes > 1) {
            cell.textLabel?.text = currentVenueName + ": " + String(currentVotes) + " votes"
        } else if (currentVotes == 1) {
            cell.textLabel?.text = currentVenueName + ": " + String(currentVotes) + " vote"
        }
        
        //cell.imageView?.image = UIImage(named: "restaurant_logo")
        /*
        if let photoURL = vote[Constants.MessageFields.photoURL], let URL = URL(string: photoURL), let data = try? Data(contentsOf: URL) {
            cell.imageView?.image = UIImage(data: data)
        }
         */
        return cell
    }
}
    

