//
//  FilterViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/8/2020.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

import UIKit
import Firebase

class FilterViewController: UIViewController
{
    // Connect to storyboard
    @IBOutlet var tableView: UITableView!
    
    var filterSettings: [String] = ["start_time", "end_time"]
    
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

extension FilterViewController: UITableViewDelegate, UITableViewDataSource {
    
    // The table view controller is standard. Not much to see here.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return filterSettings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as! FilterCell
        
        
        let setting = filterSettings[indexPath.row]
        cell.populateItem(setting: setting)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        return cell
    }
    
}


// This is the custom class for the table view cell
//
class FilterCell: UITableViewCell
{
    
    @IBOutlet weak var inputTextField: UITextField!
    private var datePicker: UIDatePicker?
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var settingLabel: UILabel!
    
    // Connect with FIRESTORE!
    var db: Firestore!
    let user = Auth.auth().currentUser
    var setting: String = ""
    var settingFlag: String = ""
    
    func populateItem(setting: String)
    {
        // setting string is "StartDate" "StartTime" "EndDate" or "EndTime"
        // Connect to firestore
        db = Firestore.firestore()
        
        // Create datepicker with toolbar for the textviews
        datePicker = UIDatePicker()
        datePicker?.datePickerMode = .dateAndTime
        createToolbar()
        inputTextField.inputView = datePicker
        inputTextField.tintColor = .clear
        
        // Define local variables for firestore queries
        self.setting = setting
        self.settingFlag = setting + "_flag"
        
        // Add selector functions to buttons
        datePicker?.addTarget(self, action: #selector(dateChanged(datePicker: )), for: .valueChanged)
        resetButton.addTarget(self, action: #selector(self.resetData), for: .touchUpInside)
        
        // Define the label on the storyboard
        if setting == "start_time" {
            settingLabel.text = "START"
        } else if setting == "end_time" {
            settingLabel.text = "END"
        }

        
        // Enable RESET button IF there is a start_time or end_time
        // Otherwise, disable it
        let collectionRef = db.collection("users").document(user!.uid).collection("settings")
        collectionRef.whereField(settingFlag, isEqualTo: true).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                print("snapshot is empty! There are no documents.")
                // This means the flag is false or DNE. Do NOT show reset button
                self.resetData(self.resetButton)
                
            } else {
                for document in (snapshot?.documents)! {
                    print("there are documents")
                    //This means the flag is true. Do show reset button
                    let myData = document.data()
                    print(myData)
                    print(document)
                    
                    let df = DateFormatter()
                    df.dateFormat = "MMMM dd, yyyy HH:MM"
                   
                    self.inputTextField.text = df.string(from: (myData[setting] as AnyObject).dateValue())
                    
                    // show reset button
                    self.showResetButton()
                }
            }
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
        // Add the reset button!!!
        showResetButton()
        
    }
    
    @objc func dateChanged(datePicker: UIDatePicker) {
        // Upload start setting to the cloud!
        // Add the message AND generate an ID for it with proper error handling.
        
        db.collection("users").document(user!.uid).collection("settings").document("filter_settings").setData([
            setting : Timestamp(date: datePicker.date),
            settingFlag : true
            ], merge: true
        ) { err in
            if let err = err {
                print("Error adding filter_settings: \(err)")
            } else {
                print("Document successfully written")
            }
        }

        
        let df = DateFormatter()
        df.dateFormat = "MMMM dd, yyyy HH:MM"
        
        inputTextField.text = df.string(from: datePicker.date)
    }
    
    func showResetButton() {
        // show accessory view
        resetButton.isHidden = false

        resetButton.isEnabled = true
        
    }
    
    @objc func resetData(_ sender: UIButton) {
        // Make the reset button go away

        resetButton.isEnabled = false
        resetButton.isHidden = true
        
        inputTextField.text = ""
        
        // Make text field long
        
        db.collection("users").document(user!.uid).collection("settings").document("filter_settings").updateData([
            setting : FieldValue.delete(),
            settingFlag : false
            ]
        ) { err in
            if let err = err {
                print("Error deleting field value: \(err)")
            } else {
                print("Field value successfully deleted")
            }
        }
        
    }


}

