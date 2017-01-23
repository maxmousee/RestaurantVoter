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
    var uid: String?
    var tips: [JSONParameters]?
    var voter = Voter()
    
    
    @IBOutlet weak var voteButton: UIBarButtonItem!
    
    @IBAction func voteForRestaurant(_ sender: Any) {
        
        if (voter.userAlreadyVotedToday()) {
            let alertController = UIAlertController(title: "User already voted today",
                                                    message: "You can't vote twice a day", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: {
                (action) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            self.uid = signInAnonymously();
            postVoteForRestaurant(theVenueId: venueId!);
            addReminderNotification();
        }
    }
    
    func showVoteAnimation() {
        let voteTL = UITextView();
        voteTL.backgroundColor = (UIColor .purple);
        voteTL.frame = CGRect(x: 0, y: ((3 * self.view.bounds.size.height)/8),
                              width: self.view.bounds.size.width,
                              height: 60);
        voteTL.textAlignment = NSTextAlignment.center
        voteTL.isEditable = false
        voteTL.isUserInteractionEnabled = false
        voteTL.font = UIFont.systemFont(ofSize: 36)
        voteTL.textColor = (UIColor .white)
        voteTL.text = Constants.Messages.userVote;
        self.view.addSubview(voteTL);
        
        let bounds = voteTL.bounds
        let smallFrame = voteTL.frame.insetBy(dx: voteTL.frame.size.width / 8, dy: voteTL.frame.size.height / 4)
        let finalFrame = smallFrame.offsetBy(dx: 0, dy: bounds.size.height)
        
        UIView.animateKeyframes(withDuration: 3.0, delay: 0.0, options: UIViewKeyframeAnimationOptions.calculationModeCubic, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                voteTL.frame = smallFrame
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                voteTL.frame = finalFrame
            }
        }, completion: { (finished: Bool) in
            voteTL.removeFromSuperview();
        })
    }
    
    func postVoteForRestaurant(theVenueId: String) {
        voter.checkWeekWinnersAndVote(theVenueId: theVenueId, title:title!, viewController: self)
        //showVoteAnimation();
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
            self.animateTable();
        }
        task.start()
    }
    
    func animateTable() {
        self.tableView.reloadData()
        
        let cells = self.tableView.visibleCells
        let tableHeight: CGFloat = self.tableView.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
        }
        
        var index = 0
        
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animate(withDuration: 1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0);
            }, completion: nil)
            
            index += 1
        }
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
