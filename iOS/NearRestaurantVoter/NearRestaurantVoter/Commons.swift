//
//  Commons.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 21/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

import Foundation
import UserNotifications
import Firebase

func getDateFormattedString(date: Date) -> String {
    
    let dayTimePeriodFormatter = DateFormatter()
    dayTimePeriodFormatter.dateFormat = "yyyy-MM-dd"
    
    let dateString = dayTimePeriodFormatter.string(from: date as Date)
    
    return dateString;
}

func getTodayFormattedString() -> String {
    return getDateFormattedString(date: Date())
}

func getLastDaysFormattedString(daysEarlier: Int) -> String {
    return getDateFormattedString(date: getEarlierdayDate(daysEarlier: daysEarlier))
}

func getEarlierdayDate(daysEarlier: Int) -> Date {
    let relativeToCurrentDay = 0 - daysEarlier;
    return Calendar.current.date(byAdding: .day, value: relativeToCurrentDay, to: Date())!
}

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

func signInAnonymously() -> String {
    var theUser = ""
    FIRAuth.auth()?.signInAnonymously() { (user, error) in
        if (error == nil) {
            theUser = user!.uid
        } else {
            print(error ?? "Unknown error to sign in");
        }
    }
    return theUser;
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

func getEarlierVoteFIRDB(daysEarlier: Int) -> FIRDatabaseReference {
    return FIRDatabase.database().reference().child(Constants.VotesFields.venues).child(getLastDaysFormattedString(daysEarlier: daysEarlier));
}

func addReminderNotification() {
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
        // Fallback on earlier versions (this works from iOS 4 to iOS 9)
        UIApplication.shared.cancelAllLocalNotifications()
        let notification = UILocalNotification()
        notification.alertBody = "Restaurant Voting Ended, check where you will eat today" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = date as Date // todo item due date (when notification will be fired) notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["UUID": Constants.Defaults.notificationId] // assign a unique identifier to the notification so that we can retrieve it later
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
}
