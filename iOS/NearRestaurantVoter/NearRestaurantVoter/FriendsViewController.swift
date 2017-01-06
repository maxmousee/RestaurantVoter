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
        
    var votes: [FIRDataSnapshot]! = []
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
        self.ref.child("votes").removeObserver(withHandle: _refHandle)
    }
    
    
    func configureDatabase() {
        ref = FIRDatabase.database().reference()
        // Listen for new messages in the Firebase database
        _refHandle = self.ref.child("votes").observe(.childAdded, with: { [weak self] (snapshot) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.votes.append(snapshot)
            strongSelf.tableView.insertRows(at: [IndexPath(row: strongSelf.votes.count-1, section: 0)], with: .automatic)
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
                /*
                let friendlyMsgLength = self.remoteConfig["friendly_msg_length"]
                if (friendlyMsgLength.source != .static) {
                    self.msglength = friendlyMsgLength.numberValue!
                    print("Friendly msg length config: \(self.msglength)")
 
 
                }
 
                 */
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
        if let votes = self.votes {
            return votes.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendTableViewCell
        //let friendInfo = friends![(indexPath as NSIndexPath).row]
        //let firstName = friendInfo["firstName"] as? String
        //let lastName = friendInfo["lastName"] as? String
        //let fullName = ((firstName != nil) ? firstName! : "") + " " + ((lastName != nil) ? lastName! : "")
        //cell.nameLabel?.text = fullName

        // Unpack message from Firebase DataSnapshot
        let voteSnapshot: FIRDataSnapshot! = self.votes[indexPath.row]
        let vote = voteSnapshot.value as! Dictionary<String, String>
        let user = vote[Constants.VotesFields.user] as String!
        let location = vote[Constants.VotesFields.location] as String!
        cell.textLabel?.text = user! + ": " + location!
        //cell.nameLabel?.text = user! + ": " + location!
        cell.imageView?.image = UIImage(named: "ic_account_circle")
        /*
        if let photoURL = vote[Constants.MessageFields.photoURL], let URL = URL(string: photoURL), let data = try? Data(contentsOf: URL) {
            cell.imageView?.image = UIImage(data: data)
        }
         */
        return cell
    }
}
    

