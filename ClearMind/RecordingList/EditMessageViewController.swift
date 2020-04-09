//
//  EditMessageViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/9/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//

import UIKit
import Firebase

class EditMessageViewController: UIViewController
{
    
    var recording: Recording!
    
    // Connect to storyboard

    @IBOutlet weak var tableView: UITableView!
    var messageSettings = [["time", ""], ["speaker", ""], ["conversation",  "" ], ["message", ""]]
    
    var message: UITextView!
    var speaker: UILabel!
    var conversation: UILabel!
    var time: UILabel!
    var messageID: String?
      
    let user = Auth.auth().currentUser
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

                
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view
        messageSettings[3][1] = recording.message ?? ""
        messageSettings[1][1] = recording.speaker ?? ""
        messageSettings[2][1] = recording.conversation ?? ""
        messageID = recording.messageID
        
        let df = DateFormatter()
        df.dateFormat = "MMMM/dd/YYYY hh:mm"
        messageSettings[0][1] = df.string(from: (recording.time?.dateValue())!)
        
    }
    
    // This creates a toolbar and "Save" button when editing a textfield
    func createToolbar()
    {
        // Create the toolbar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        // Add the done button
        let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(MessageCell.dismissKeyboard))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        // Adjust the colors and present the done button as a subjview
        doneButton.tintColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        message.inputAccessoryView = toolBar
    }
    
    
    // Show the navigation bar because we want the back button
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(false)
    }
    
}

extension EditMessageViewController: UITableViewDelegate, UITableViewDataSource {
    
    // The table view controller is standard. Not much to see here.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return messageSettings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditMessageCell", for: indexPath) as! EditMessageCell
        let setting = messageSettings[indexPath.row]
        cell.populateItem(setting: setting)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
    
}


// This is the custom class for the table view cell
//
class EditMessageCell: UITableViewCell
{
    
    @IBOutlet weak var inputTextField: UITextField!
    
    private var datePicker: UIDatePicker?
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var settingLabel: UILabel!
    
    // Connect with FIRESTORE!
    var db: Firestore!
    let user = Auth.auth().currentUser

    
    func populateItem(setting: [String])
    {
        // setting string is "StartDate" "StartTime" "EndDate" or "EndTime"
        // Connect to firestore
        db = Firestore.firestore()
        createToolbar()

        
        if setting[0] == "time" {
            // Create datepicker with toolbar for the textviews
             inputTextField.text = setting[1]
            
            datePicker = UIDatePicker()
            datePicker?.datePickerMode = .dateAndTime
            inputTextField.inputView = datePicker
            inputTextField.tintColor = .clear
            
            settingLabel.text = "TIME"
        } else if setting[0] == "speaker" {
            inputTextField.text = setting[1]
            
            inputTextField.becomeFirstResponder()
            inputTextField.tintColor = .clear
            settingLabel.text = "SPEAKER"
        } else if setting[0] == "converasation" {
             inputTextField.text = setting[1]
            inputTextField.becomeFirstResponder()
            inputTextField.tintColor = .clear
            settingLabel.text = "CONVO"
        } else if setting[0] == "message" {
             inputTextField.text = setting[1]
            inputTextField.becomeFirstResponder()
            inputTextField.tintColor = .clear
            settingLabel.text = "MESSAGE"
        }

    
    }
    
    func createToolbar()
    {
        // Create the toolbar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        // Add the done button
        let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(dismissDatePicker))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        // Adjust the colors and present the done button as a subjview
        doneButton.tintColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        inputTextField.inputAccessoryView = toolBar
    }
    
    @objc func dismissDatePicker() {
        inputTextField.endEditing(true)
    
    }

    
}
