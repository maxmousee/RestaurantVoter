//
//  Voter.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 22/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import Foundation
import Firebase

class Voter {
    var didWin = false
    
    func postVote(theVenueId: String, title: String) {
        let ref = getReferenceVoteFIRDB()
        ref.child(Constants.VotesFields.venues).child(theVenueId).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get votes value
            let value = snapshot.value as? NSDictionary
            var currentVotes = value?[Constants.VotesFields.voteCount] as? Int ?? 0
            // ...
            currentVotes += 1;
            let vote = [Constants.VotesFields.voteCount: currentVotes,
                        Constants.VotesFields.locationName: title] as [String : Any]
            let childUpdates = ["/\(Constants.VotesFields.venues)/\(theVenueId)/": vote]
            ref.updateChildValues(childUpdates)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    //func checkIfWinner(daysBeforeToday: Int, venueIdToCheck: String, completionHandler: @escaping (Bool) -> ()) {
    func checkIfWinner(daysBeforeToday: Int, venueIdToCheck: String, viewController: UIViewController) {
        var winnerId = String()
        let ref = getEarlierVoteFIRDB(daysEarlier: daysBeforeToday);
        ref.child(Constants.VotesFields.venues).queryOrdered(byChild: Constants.VotesFields.voteCount).queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            // Get votes for winner venue

            let enumerator = snapshot.children
            while let currentVenue = enumerator.nextObject() as? FIRDataSnapshot {
                let value = currentVenue.value as? NSDictionary
                let currentVotes = value?[Constants.VotesFields.voteCount] as? Int ?? 0
                winnerId = currentVenue.key as String
                print("Current votes of yesterday winner " + String(currentVotes))
                print("Id of days earlier, " + String(daysBeforeToday) + " winner " + winnerId)
                if (venueIdToCheck == winnerId) {
                    print("Found winner");
                    self.didWin = true
                    self.showCantVoteForPreviousWinner(viewController: viewController)
                    //return true
                    //completionHandler(true)
                } else {
                    //completionHandler(false)
                }
            }
        }) { (error) in
            print(error.localizedDescription)
            //completionHandler(false)
            self.didWin = true
        }
    }
    
    func showCantVoteForPreviousWinner(viewController: UIViewController) {
        let alertController = UIAlertController(title: "Can't vote for this venue",
                                                message: "You can't vote for a previously winner venue", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: {
            (action) -> Void in
            viewController.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(okAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    /*
    func showVoteAlert(viewController: UIViewController) {
        let alertController = UIAlertController(title: "Voted!",
                                                message: "Thanks for voting", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: {
            (action) -> Void in
            viewController.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(okAction)
        viewController.present(alertController, animated: true, completion: nil)
    }
 */
    
    func checkWeekWinnersAndVote(theVenueId: String, title: String, viewController: UIViewController) {
        //for every winner of last week
        print("Check if " + theVenueId + " was winner in the previous 7 days")
        for day in 1...7 {
            checkIfWinner(daysBeforeToday: day, venueIdToCheck: theVenueId, viewController: viewController);
            }
        // can vote
        postVote(theVenueId: theVenueId, title: title);
        //showVoteAlert(viewController: viewController);
    }

    func userAlreadyVotedToday() -> Bool {
        /*
         let voteTimestamp = UserDefaults.standard.double(forKey: Constants.Defaults.lastVoteTimestamp);
         if (voteTimestamp == 0) {
         return false;
         }
         if (Date(timeIntervalSince1970: (voteTimestamp + Constants.NumValues.secondsInADay)).timeIntervalSince1970 > Date().timeIntervalSince1970) {
         return true;
         }
         */
        return false;
    }

}
