//
//  Commons.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 21/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import Foundation
import Firebase

func getDateFormattedString(date: Date) -> String {
    
    let dayTimePeriodFormatter = DateFormatter()
    dayTimePeriodFormatter.dateFormat = "yyyy-MM-dd"
    
    let dateString = dayTimePeriodFormatter.string(from: date as Date)
    
    //print(dateString);
    return dateString;
}

func checkWeekWinners(theVenueId: String) -> Bool {
    //for every winner of last week
    let isEqual = (theVenueId == getYesterdayElectedVenueId());
    return isEqual;
}


func getTodayFormattedString() -> String {
    return getDateFormattedString(date: Date())
}

func getYesterdayFormattedString() -> String {
    return getDateFormattedString(date: getYesterdayDate())
}

func getYesterdayDate() -> Date {
    return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
}

/*
func addEllectedToWeeklyLit() {
    let yesterday = getYesterdayDate()
    let weeklyWinnersDB = getWeeklyWinnersVoteFIRDB()
    let yesterdayVotesDB = getReferenceVoteFIRDB()
}
 */

func getWeekFormattedString() -> String {
    let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.ISO8601)!
    let myWeekComponents = myCalendar.components(NSCalendar.Unit.weekOfYear, from: NSDate() as Date)
    let myYearOfWeekComponents = myCalendar.components(NSCalendar.Unit.yearForWeekOfYear, from: NSDate() as Date)
    let weekNumber = myWeekComponents.weekOfYear;
    let yearNumber = myYearOfWeekComponents.yearForWeekOfYear
    let weekOfYearString = String(describing: yearNumber) + "-" + String(describing: weekNumber)
    print(weekOfYearString);
    return weekOfYearString;
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

func getReferenceVoteFIRDB() -> FIRDatabaseReference {
    return FIRDatabase.database().reference().child(Constants.VotesFields.venues).child(getTodayFormattedString());
}

func getYesterdayVoteFIRDB() -> FIRDatabaseReference {
    return FIRDatabase.database().reference().child(Constants.VotesFields.venues).child(getYesterdayFormattedString());
}

func getWeeklyWinnersVoteFIRDB() -> FIRDatabaseReference {
    return FIRDatabase.database().reference().child(Constants.VotesFields.weeklyWinners).child(getWeekFormattedString());
}

func getYesterdayElectedVenueId() -> String {
    return "506b5732e4b0c4c151d0c180"
}

func addYesterdayWeeklyWinner() {
    let yesterdayWinnerVenueId = getYesterdayElectedVenueId()
    let currentRef = getWeeklyWinnersVoteFIRDB();
    currentRef.child(yesterdayWinnerVenueId).observeSingleEvent(of: .value, with: { (snapshot) in
        // Get votes value
        let value = snapshot.value as? NSDictionary
        let won = value?[Constants.VotesFields.won] as? Bool ?? true
        let ellectedVenue = [Constants.VotesFields.won: won] as [String : Any]
        let childUpdates = ["/\(Constants.VotesFields.venues)/\(yesterdayWinnerVenueId)/": ellectedVenue]
        currentRef.ref.updateChildValues(childUpdates)
        
    }) { (error) in
        print(error.localizedDescription)
    }
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
