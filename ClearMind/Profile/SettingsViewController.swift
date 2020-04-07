//
//  SettingsViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/8/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

// The function of this view controller is the populate the settings page with one item.
import UIKit
import UserNotifications

class SettingsViewController: UIViewController
{
    // Connect to storyboard
    @IBOutlet var tableView: UITableView!
    
    
    let settingsInformation = [
            ["Notifications", "Recieve updates."]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        

    }
    
    // Show the navigation bar because we want the back button
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    // The table view controller is standard. Not much to see here.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {

        return settingsInformation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        
        cell.imageView1.image = nil
        
        let entry = settingsInformation[indexPath.row]
        cell.itemTitle.text = entry[0]
        cell.populateItem(event: entry)
        
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        
        return cell
    }
    
}

import UserNotifications

// This is the custom class for the table view cell
//
class SettingCell: UITableViewCell
{
    @IBOutlet var itemTitle: UILabel!
    @IBOutlet var itemDescription: UILabel!
    @IBOutlet var itemButton: UIButton!
    
    var switchView = UISwitch()
    var imageView1 = UIImageView()
    
    func populateItem(event: [String])
    {
        itemTitle.text = event[0]
        if event[0] == "Notifications" {
            
            createButton()
            
            // Add a switch to this table view cell programmatically
            switchView = UISwitch(frame: .zero)
            switchView.setOn(self.pushEnabledAtOSLevel(), animated: true)
            switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            itemButton.addSubview(switchView)
            switchView.center = CGPoint(x: itemButton.frame.size.width  / 2,
                                       y: itemButton.frame.size.height / 2)
            switchView.onTintColor = UIColor.lightGray
            itemButton.addTarget(self, action: #selector(self.toggleSwitch), for: .touchUpInside)
        }
        
        // Add the description, too.
        itemDescription.text = event[1]
    }

    // The switch redirects to settings if push notifications need to be turned off
    //
    @objc func switchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            
            // Navigate to settings
            //
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                    if !granted {
                        self.openSettings()
                    }
                }
            
            
        } else {
            
            //Turn off post notifications
            //
            if pushEnabledAtOSLevel() {
                self.openSettings()
            }
           
            
        }
    }
    
    @objc func toggleSwitch(_ sender: UIButton) {
        if (switchView.isOn) {
            switchView.setOn(false, animated: true)
            switchChanged(switchView)
        } else {
            switchView.setOn(true, animated: true)
            switchChanged(switchView)
        }
    }
    
    // This function programmatically creates a button to register a change in the switch
    //
    func createButton() {
        itemButton.layer.cornerRadius = 40
        self.accessoryView = itemButton
        
        itemButton.backgroundColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        itemButton.layer.shadowOpacity = 1
        itemButton.layer.shadowRadius = 3
        itemButton.layer.shadowOffset = CGSize(width: 0, height: 0.3)
        itemButton.layer.shadowColor = UIColor.black.cgColor
        itemButton.isEnabled = true
    }
    
    // This gets the current staus of push notifications
    //
    func pushEnabledAtOSLevel() -> Bool {
        guard let currentSettings = UIApplication.shared.currentUserNotificationSettings?.types else { return false }
        return currentSettings.rawValue != 0
    }
    
    // This opens settings for the user
    //
    func openSettings() {
        if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings as URL)
        }
    }
    
}


