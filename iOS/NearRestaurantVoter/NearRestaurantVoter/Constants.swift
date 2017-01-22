//
//  Constants.swift
//  NearRestaurantVoter
//
//  Created by Natan Facchin on 06/01/17.
//  Copyright © 2017 NFS Industries. All rights reserved.
//

struct Constants {
    
    struct NotificationKeys {
        static let SignedIn = "onSignInCompleted"
    }
    
    struct Segues {
        static let SignInToFp = "SignInToFP"
        static let FpToSignIn = "FPToSignIn"
    }
    
    struct Defaults {
        static let lastVoteTimestamp = "lastVoteTimestamp"
        static let notificationId = "nearRestaurantVoterNotificationId"
    }
    
    struct NumValues {
        static let secondsInADay = 86400.00
        static let secondsInAWeek = NumValues.secondsInADay * 7
        static let mostVotedCount = 200
    }
    
    struct Messages {
        static let userVote = "Voted!"
    }
    
    struct VotesFields {
        static let users = "users"
        static let userId = "userId"
        static let venues = "venues"
        static let timestamp = "timestamp"
        static let locationId = "locationId"
        static let votes = "votes"
        static let voteCount = "voteCount"
        static let userVoted = "userVoted"
        static let locationName = "locationName"
        static let weeklyWinners = "weeklyWinners"
        static let won = "won"
    }
}
