//
//  CustomRecordViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/18/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//
import UIKit
import Firebase

class CustomRecordViewController: UIViewController
{
    var db: Firestore!
    let user = Auth.auth().currentUser
    
    var oldConversation: String?
    var newConversationID = UUID().uuidString
    
    @IBOutlet weak var tableView: UITableView!
    
    var recordSettings: [String] = ["time", "conversation", "speaker", "message"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        
        // [START setup]
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        // Add navigation bar button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Add", style: .done, target: self, action: #selector(self.addMessage(sender:)))
        
        // Get most recent conversation
        let messagesRef = db.collection("users").document(user!.uid).collection("messages")
        let query = messagesRef.order(by: "time_seconds", descending: true).limit(to: 1)
        
        query.getDocuments { (snapshot, err) in
            if let err = err {
                print("\(err.localizedDescription)")
            } else if snapshot!.isEmpty {
                // No conversations
                return
            } else {
                let lastRecording = snapshot!.documents.compactMap({Recording(dictionary: $0.data())})
                
                self.oldConversation = lastRecording[0].conversation
                self.newConversationID = lastRecording[0].conversationID ?? UUID().uuidString
            }
        
            
        }
        
    }
    
    // Show the navigation bar because we want the back button
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @objc func addMessage(sender: UIBarButtonItem) {
        
        let indexpathForTime = NSIndexPath(row: 0, section: 0)
        let timeCell = tableView.cellForRow(at: indexpathForTime as IndexPath) as! RecordCell
        
        let indexpathForConversation = NSIndexPath(row: 1, section: 0)
        let conversationCell = tableView.cellForRow(at: indexpathForConversation as IndexPath) as! RecordCell
        
        let indexpathForSpeaker = NSIndexPath(row: 2, section: 0)
        let speakerCell = tableView.cellForRow(at: indexpathForSpeaker as IndexPath) as! RecordCell
        
        let indexpathForMessage = NSIndexPath(row: 3, section: 0)
        let messageCell = tableView.cellForRow(at: indexpathForMessage as IndexPath) as! RecordCell

        if timeCell.inputTextField.text! == "" || conversationCell.inputTextField.text! == "" || speakerCell.inputTextField.text! == "" || messageCell.inputTextField.text! == "" {

            let alert = UIAlertController(title: "Error", message: "Incomplete Message", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            // Add the above to the firestore database
            addToBothCollections(message: messageCell.inputTextField.text!, conversation: conversationCell.inputTextField.text!, speaker: speakerCell.inputTextField.text!, time: timeCell.timestamp!, time_seconds: timeCell.timestamp!.seconds)
            

            self.navigationController?.popViewController(animated: true)

        }
        
    }
    
}

extension CustomRecordViewController: UITableViewDelegate, UITableViewDataSource {
    
    // The table view controller is standard. Not much to see here.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return recordSettings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! RecordCell
        
        
        let setting = recordSettings[indexPath.row]
        cell.populateItem(setting: setting)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        return cell
    }
    
}


// This is the custom class for the table view cell
//
class RecordCell: UITableViewCell, UITextFieldDelegate
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
    var counter = 0
    var timestamp: Timestamp!
    
    func populateItem(setting: String)
    {
        // setting string is "StartDate" "StartTime" "EndDate" or "EndTime"
        // Connect to firestore
        db = Firestore.firestore()
        
        // Create toolbar for keyboard/datepicker
        createToolbar()
        
        // Update the UI
        inputTextField.tintColor = .clear
        
        // Define local variables for queries
        self.setting = setting
        
        // Add reset button function
        resetButton.addTarget(self, action: #selector(self.resetData), for: .touchUpInside)
        
        // Add delegate to text field
        inputTextField.delegate = self
        
        
        // Define the label on the storyboard
        if setting == "time" {
            settingLabel.text = "TIME"
            
            let df = DateFormatter()
            df.dateFormat = "MMMM dd, yyyy HH:MM"
            
            inputTextField.text = df.string(from: Date())
            timestamp = Timestamp(date: Date())
            
            // Create datepicker with toolbar for the textviews
            datePicker = UIDatePicker()
            datePicker?.datePickerMode = .dateAndTime
            inputTextField.inputView = datePicker
            
            // Add function to datepicker
            datePicker?.addTarget(self, action: #selector(dateChanged(datePicker: )), for: .valueChanged)
            
            resetButton.setTitle("NOW", for: .normal)

        } else if setting == "conversation" {
            settingLabel.text = "CONVERSATION"
            inputTextField.text = "Default Conversation"
            
            resetButton.setTitle("DEFAULT", for: .normal)
        } else if setting == "speaker" {
            settingLabel.text = "SPEAKER"
            inputTextField.text = user?.displayName
            
            resetButton.setTitle("ME", for: .normal)
        } else if setting == "message" {
            settingLabel.text = "MESSAGE"
            inputTextField.text = "Default Message"
            
            resetButton.setTitle("NONE", for: .normal)

        }
    }
    
    // Clear textfield when someone clicks on them and starts editing
    func textFieldDidBeginEditing(_ textField: UITextField) {
        inputTextField.text = ""
        print("tried to clear")
    }
    
    func createToolbar()
    {
        // Create the toolbar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        // Add the done button
        let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(dismissToolbar))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        // Adjust the colors and present the done button as a subjview
        doneButton.tintColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        inputTextField.inputAccessoryView = toolBar
    }
    
    @objc func dismissToolbar() {
        inputTextField.endEditing(true)
        // Add the reset button!!!
        showResetButton()
        
        
    }
    
    
    
    @objc func dateChanged(datePicker: UIDatePicker) {
        let df = DateFormatter()
        df.dateFormat = "MMMM dd, yyyy HH:MM"
        
        inputTextField.text = df.string(from: datePicker.date)
        timestamp = Timestamp(date: datePicker.date)
    }
    
    func showResetButton() {
        resetButton.isHidden = false
        resetButton.isEnabled = true
    }
    
    @objc func resetData(_ sender: UIButton) {
        // Make the reset button go away

        resetButton.isEnabled = false
        resetButton.isHidden = true
        
        if setting == "time" {
            let df = DateFormatter()
            df.dateFormat = "MMMM dd, yyyy HH:MM"
            
            inputTextField.text = df.string(from: Date())
            timestamp = Timestamp(date: Date())
            
        } else if setting == "conversation" {
            inputTextField.text = "Default Conversation"
            
            
        } else if setting == "speaker" {
            inputTextField.text = user?.displayName

        } else if setting == "message" {
            inputTextField.text = "Default Message"
        }
        
        
        // Make text field long
    }
}

extension CustomRecordViewController {
    
    func addToBothCollections(message: String, conversation: String, speaker: String, time: Timestamp, time_seconds: Int64) {
        
        // If the conversation is not the same as the old one, then create a new conversationID
        if oldConversation == nil || conversation != oldConversation {
            newConversationID = UUID().uuidString
        }
        oldConversation = conversation
        
        // ADD TO THE MESSAGES COLLECTION
        let user = Auth.auth().currentUser
        let df = DateFormatter()
        df.dateFormat = "MMMM, yyyy"

        let get_string = message
        // STRING -> LIST OF WORDS
        let array_of_lowercase_words = get_string.lowercased().stripped.components(separatedBy: " ")
        let identifiers_lowercase = [conversation.lowercased(), speaker.lowercased(), df.string(from: Date()).lowercased()]
        
        // Add the message AND generate an ID for it with proper error handling.
        var ref: DocumentReference? = nil
        let newDocumentID = UUID().uuidString
        ref = db.collection("users").document(user!.uid).collection("messages").addDocument(data: [
            "message" : message,
            "conversation" : conversation, // User can MANUALLY set/EDIT this later
            "speaker" : speaker, // PYTHON MLKIT should give this
            "time" : time,
            "time_seconds" : time_seconds,
            "messageID" : newDocumentID,
            "conversationID": newConversationID,
            
            // Firestore only handles LOWERCASE and can only serach in arrays
            "search_insensitive" : Array(Set(identifiers_lowercase + array_of_lowercase_words))
            ]
        ) { err in
            if let err = err {
                print("Error adding document to standard messages: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
        
        // ADD TO THE FILTERED MESSAGES COLLECTION
        var tentatively_add = true
        var counter = 0

        // Start time
        let startRef = db.collection("users").document(user!.uid).collection("settings")
        startRef.whereField("start_time_flag", isEqualTo: true).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                print("There is no start_time when adding new document to messages, maybe messages filtered")
                // This means the flag is false or DNE. Do NOT change query
            } else {
                for document in (snapshot?.documents)! {
                    print("Found a start_time in the filter when adding new document to messages, maybe messages filtered")
                    //This means the flag is true. Do update query.
                    let myData = document.data()
                    
                    if time_seconds < (myData["start_time"] as! Timestamp).seconds {
                        tentatively_add = false
                    }
                }
            }
            counter += 1
            self.finalizeAdd(counter: counter, flag: tentatively_add, message: message, conversation: conversation, speaker: speaker, time: time, time_seconds: time_seconds)
        }
        
        // End time
        let endRef = db.collection("users").document(user!.uid).collection("settings")
        endRef.whereField("end_time_flag", isEqualTo: true).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                print("There is no end_time when adding new document to messages, maybe messages filtered.")
                // This means the flag is false or DNE. Do NOT change query
                
            } else {
                for document in (snapshot?.documents)! {
                    print("Found an end_time in the filter when adding new document to messages, maybe messages filtered")
                    //This means the flag is true. Do update query.
                    let myData = document.data()
                    
                    if time_seconds > (myData["end_time"] as! Timestamp).seconds {
                        tentatively_add = false
                    }
                    
                }
            }
            counter += 1
            self.finalizeAdd(counter: counter, flag: tentatively_add, message: message, conversation: conversation, speaker: speaker, time: time, time_seconds: time_seconds)
        }
    }
    
    func finalizeAdd(counter: Int, flag: Bool, message: String, conversation: String, speaker: String, time: Timestamp, time_seconds: Int64) {
        if counter == 2 && flag {
            
            let df = DateFormatter()
            df.dateFormat = "MMMM, yyyy"
            
            let get_string = message
            // STRING -> LIST OF WORDS
            let array_of_lowercase_words = get_string.lowercased().stripped.components(separatedBy: " ")
            let identifiers_lowercase = [conversation.lowercased(), speaker.lowercased(), df.string(from: Date()).lowercased()]
            
            // Add the message AND generate an ID for it with proper error handling.
            let newDocumentID = UUID().uuidString
            db.collection("users").document(user!.uid).collection("messages_filtered").addDocument(data: [
                "message" : message,
                "conversation" : conversation, // User can MANUALLY set/EDIT this later
                "speaker" : speaker, // PYTHON MLKIT should give this
                "time" : time,
                "time_seconds" : time_seconds,
                "messageID" : newDocumentID,
                "conversationID": newConversationID,
                
                // Firestore only handles LOWERCASE and can only serach in arrays
                "search_insensitive" : Array(Set(identifiers_lowercase + array_of_lowercase_words))
                ]
            ) { err in
                if let err = err {
                    print("Error adding document to filtered messages: \(err)")
                } else {
                    print("Document added to filtered messages")
                }
            }
        }
    }
    
    // Unwind segue
    @IBAction func unwindSegue(segue: UIStoryboardSegue) { }

}


