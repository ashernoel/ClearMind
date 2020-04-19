//
//  FilterViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/8/2020.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

import UIKit
import Firebase

class FilterViewController: UIViewController, UISearchBarDelegate
{
    // Connect to storyboard
    var db: Firestore!
    let user = Auth.auth().currentUser
    
    @IBOutlet weak var inputTextFieldStart: UITextField!
    @IBOutlet weak var inputTextFieldEnd: UITextField!

    private var datePicker: UIDatePicker?
    @IBOutlet weak var resetButtonStart: UIButton!
    @IBOutlet weak var resetButtonEnd: UIButton!
    @IBOutlet weak var settingLabelStart: UILabel!
    @IBOutlet weak var settingLabelEnd: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var settingStart: String = "start_time"
    var settingStartFlag: String = "start_time_flag"
    var settingEnd: String = "end_time"
    var settingEndFlag: String = "end_time_flag"
    var counter = 0
    var search = false
    
    // conversations data structure:
    // conversations[0] = converation name
    // conversations[1] = list of people in conversation
    // conversations[2] = time
    // conversations[3] = convo name lowercase [for search]
    // conversations[4] = people in lowercase [for search]
    var conversations = [[String]]()
    var allConversations = [Recording]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START setup]
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        
        // Create datepicker with toolbar for the textviews
        let datePickerStart = UIDatePicker()
        let datePickerEnd = UIDatePicker()
        datePickerStart.datePickerMode = .dateAndTime
        datePickerEnd.datePickerMode = .dateAndTime
        createToolbarStart()
        createToolbarEnd()
        inputTextFieldStart.inputView = datePickerStart
        inputTextFieldEnd.inputView = datePickerEnd
        inputTextFieldStart.tintColor = .clear
        inputTextFieldEnd.tintColor = .clear
        
        // Add selector functions to buttons
        datePickerStart.addTarget(self, action: #selector(dateChangedStart(datePicker: )), for: .valueChanged)
        datePickerEnd.addTarget(self, action: #selector(dateChangedEnd(datePicker: )), for: .valueChanged)
        resetButtonStart.addTarget(self, action: #selector(self.resetDataStart), for: .touchUpInside)
        resetButtonEnd.addTarget(self, action: #selector(self.resetDataEnd), for: .touchUpInside)
        
        settingLabelStart.text = "START"
        settingLabelEnd.text = "END"
        
        // Populate the Conversations
       // getConversations()
        

        // Enable RESET button IF there is a start_time or end_time
        // Otherwise, disable it
        let collectionRef1 = db.collection("users").document(user!.uid).collection("settings")
        collectionRef1.whereField(settingStartFlag, isEqualTo: true).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                print("snapshot is empty! There are no documents.")
                // This means the flag is false or DNE. Do NOT show reset button
                self.hideDataStart(self.resetButtonStart)
                self.createFilteredCollection()
            } else {
                for document in (snapshot?.documents)! {
                    print("there is a document")
                    //This means the flag is true. Do show reset button
                    let myData = document.data()
                    print(myData)
                    print(document)
                    
                    let df = DateFormatter()
                    df.dateFormat = "MMMM dd, yyyy HH:MM"
                   
                    self.inputTextFieldStart.text = df.string(from: (myData[self.settingStart] as AnyObject).dateValue())
                    
                    // show reset button
                    self.showResetButtonStart()
                }
            }
        }
        let collectionRef2 = db.collection("users").document(user!.uid).collection("settings")
        collectionRef2.whereField(settingEndFlag, isEqualTo: true).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                print("snapshot is empty! There are no documents.")
                // This means the flag is false or DNE. Do NOT show reset button
                self.hideDataEnd(self.resetButtonEnd)
                
            } else {
                for document in (snapshot?.documents)! {
                    print("there is a document")
                    //This means the flag is true. Do show reset button
                    let myData = document.data()
                    print(myData)
                    print(document)
                    
                    let df = DateFormatter()
                    df.dateFormat = "MMMM dd, yyyy HH:MM"
                   
                    self.inputTextFieldEnd.text = df.string(from: (myData[self.settingEnd] as AnyObject).dateValue())
                    
                    // show reset button
                    self.showResetButtonEnd()
                }
            }
        }
    }
    
    // Show the navigation bar because we want the back button
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(false)
        // Remove content from search bar when leaving
        searchBar.text = ""
        search = false
        
    }
    
    
    func createToolbarStart()
    {
        // Create the toolbar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        // Add the done button
        let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(dismissDatePickerStart(sender: )))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        // Adjust the colors and present the done button as a subjview
        doneButton.tintColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        inputTextFieldStart.inputAccessoryView = toolBar
    }
    func createToolbarEnd()
    {
        // Create the toolbar
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        // Add the done button
        let doneButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(dismissDatePickerEnd(sender: )))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        // Adjust the colors and present the done button as a subjview
        doneButton.tintColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        inputTextFieldEnd.inputAccessoryView = toolBar
    }
    
    @objc func dismissDatePickerStart(sender: UIDatePicker) {
        inputTextFieldStart.endEditing(true)
        // Add the reset button!!!
        showResetButtonStart()
        // add correct documents to filtered collection
        createFilteredCollection()
        
    }
    
    @objc func dismissDatePickerEnd(sender: UIDatePicker) {
        inputTextFieldEnd.endEditing(true)
        // Add the reset button!!!
        showResetButtonEnd()
        // add correct documents to filtered collection
        createFilteredCollection()
        
    }
    @objc func dateChangedStart(datePicker: UIDatePicker) {
        // Upload start setting to the cloud!
        // Add the message AND generate an ID for it with proper error handling.
        
        db.collection("users").document(user!.uid).collection("settings").document("filter_settings").setData([
            settingStart : Timestamp(date: datePicker.date),
            settingStartFlag : true
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
        
        inputTextFieldStart.text = df.string(from: datePicker.date)
    }
    
    @objc func dateChangedEnd(datePicker: UIDatePicker) {
        // Upload start setting to the cloud!
        // Add the message AND generate an ID for it with proper error handling.
        
        db.collection("users").document(user!.uid).collection("settings").document("filter_settings").setData([
            settingEnd : Timestamp(date: datePicker.date),
            settingEndFlag : true
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
        inputTextFieldEnd.text = df.string(from: datePicker.date)
    }
    
    func showResetButtonStart() {
        // show accessory view
        resetButtonStart.isHidden = false
        resetButtonStart.isEnabled = true
    }
    func showResetButtonEnd() {
        // show accessory view
        resetButtonEnd.isHidden = false
        resetButtonEnd.isEnabled = true
    }
    
    @objc func resetDataStart(_ sender: UIButton) {
        // Make the reset button go away

        resetButtonStart.isEnabled = false
        resetButtonStart.isHidden = true
        inputTextFieldStart.text = ""
        
        // Make text field long
        
        db.collection("users").document(user!.uid).collection("settings").document("filter_settings").updateData([
            settingStart : FieldValue.delete(),
            settingStartFlag : false
            ]
        ) { err in
            if let err = err {
                print("Error deleting field value: \(err)")
            } else {
                print("Field value successfully deleted")
            }
        }
        
        createFilteredCollection()
    }
    
    @objc func hideDataStart(_ sender: UIButton) {
         // Make the reset button go away

         resetButtonStart.isEnabled = false
         resetButtonStart.isHidden = true
         inputTextFieldStart.text = ""
         
         // Make text field long
         
         db.collection("users").document(user!.uid).collection("settings").document("filter_settings").updateData([
             settingStart : FieldValue.delete(),
             settingStartFlag : false
             ]
         ) { err in
             if let err = err {
                 print("Error deleting field value: \(err)")
             } else {
                 print("Field value successfully deleted")
             }
         }
        
         
     }
    
    @objc func resetDataEnd(_ sender: UIButton) {
        // Make the reset button go away

        resetButtonEnd.isEnabled = false
        resetButtonEnd.isHidden = true
        inputTextFieldEnd.text = ""
        
        // Make text field long
        
        db.collection("users").document(user!.uid).collection("settings").document("filter_settings").updateData([
            settingEnd : FieldValue.delete(),
            settingEndFlag : false
            ]
        ) { err in
            if let err = err {
                print("Error deleting field value: \(err)")
            } else {
                print("Field value successfully deleted")
            }
        }
        
        createFilteredCollection()
    }
    
    @objc func hideDataEnd(_ sender: UIButton) {
        // Make the reset button go away

        resetButtonEnd.isEnabled = false
        resetButtonEnd.isHidden = true
        inputTextFieldEnd.text = ""
        
        // Make text field long
        
        db.collection("users").document(user!.uid).collection("settings").document("filter_settings").updateData([
            settingEnd : FieldValue.delete(),
            settingEndFlag : false
            ]
        ) { err in
            if let err = err {
                print("Error deleting field value: \(err)")
            } else {
                print("Field value successfully deleted")
            }
        }
    }
    
    func createFilteredCollection() {
        
        // Delete all old messages
        let filteredColRef = db.collection("users").document(user!.uid).collection("messages_filtered")
        filteredColRef.getDocuments{ (snapshot, error) in
            if error != nil {
                print("Error getting filtered documents for deletion")
            } else if (snapshot?.isEmpty)! {
                print("Filtered messages are empty")
                // This means the flag is false or DNE. Do NOT change query
            } else {
                for document in (snapshot?.documents)! {
                    filteredColRef.document(document.documentID).delete()
                }
            }
        }

        var counter = 0
        let messagesRef = db.collection("users").document(user!.uid).collection("messages")
        var query = messagesRef.whereField("time_seconds", isLessThan: (Timestamp(date: Date()).seconds))

        // Start time
        let startRef = db.collection("users").document(user!.uid).collection("settings")
        startRef.whereField("start_time_flag", isEqualTo: true).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                print("There is no start_time. Query is not mutated")
                // This means the flag is false or DNE. Do NOT change query
            } else {
                for document in (snapshot?.documents)! {
                    print("Found a start_time in the filter")
                    //This means the flag is true. Do update query.
                    let myData = document.data()
                    
                    query = query.whereField("time_seconds", isGreaterThan: (myData["start_time"] as! Timestamp).seconds)
                }
            }
            counter += 1
            self.finalizeQuery(query: query, counter: counter)
        }
        
        // End time
        let endRef = db.collection("users").document(user!.uid).collection("settings")
        endRef.whereField("end_time_flag", isEqualTo: true).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting document: \(err)")
            } else if (snapshot?.isEmpty)! {
                print("There is no end_time. Query is not mutated")
                // This means the flag is false or DNE. Do NOT change query
                
            } else {
                for document in (snapshot?.documents)! {
                    print("Found an end_time in the filter. Updating Query")
                    //This means the flag is true. Do update query.
                    let myData = document.data()

                    query = query.whereField("time_seconds", isLessThan: (myData["end_time"] as! Timestamp).seconds)
                    
                }
            }
            counter += 1
            self.finalizeQuery(query: query, counter: counter)
        }
        
    }
    
    func finalizeQuery(query: Query, counter: Int) {
        if counter == 2 {
            // Build the collection
            let filteredColRef = db.collection("users").document(user!.uid).collection("messages_filtered")
            query.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else if (snapshot?.isEmpty)! {
                    print("snapshot is empty! There are no documents in the filter.")
                } else {
                    for document in (snapshot?.documents)! {
                        print("there is a document")
                        let myData = document.data()
                        
                        filteredColRef.addDocument(data: myData)
                    }
                }
                
                print("finalized query")
                // Repopulate the conversations
                self.getConversations()
            }
            
            
        }
    }
    
    func getConversations() {
        
        // Clear all previous recordings
        conversations.removeAll()
        allConversations.removeAll()

        
        // Get all of the data from the filtered collection
        let messagesRef = db.collection("users").document(user!.uid).collection("messages_filtered")
        let query = messagesRef.whereField("time_seconds", isLessThan: (Timestamp(date: Date()).seconds)).order(by: "time_seconds", descending: true)
        query.getDocuments { (snapshot, err) in
            if let err = err {
                print("\(err.localizedDescription)")
            } else {
                    let newRecordings = snapshot!.documents.compactMap({Recording(dictionary: $0.data())})
                    self.allConversations.append(contentsOf: newRecordings)
                    // If NOT searching, then list bottom up and do not accept clicks!
                    if (!self.search) {
                        self.tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
                    }
                
                    self.loadConversations()
            }
        }
    }
        
    func loadConversations() {
        // Define date formatter
        let df = DateFormatter()
        df.dateFormat = "MMMM dd, HH:MM"
        
        print("LOADING CONVERSATINOS")
        print(conversations)
        if !allConversations.isEmpty {
            // Contruct the conversation array from the allConversations data
            for recording in allConversations {
                // If we do not yet have this conversation
                
                // if the recordig is NOT new, check if speaker is already in the speaker array. If NOT, then add it!
                //last speakers
                
                // If the conversation is not already contained in the name of converstaion
                if conversations.last == nil || conversations.last![0] != recording.conversation! {
                    conversations.append([recording.conversation!, recording.speaker!, df.string(from: (recording.time!).dateValue()), recording.conversation!.lowercased(), recording.speaker!.lowercased()])
                } else if !conversations.last![1].contains(recording.speaker!) {
                    // If the conversation is already in the list, then check
                    // if not contains the speaker -> add it
                    
                    var lastConversation = conversations.last
                    conversations.removeLast()
                    lastConversation![1] = lastConversation![1] + " " + recording.speaker!
                    lastConversation![4] = lastConversation![4] + " " + (recording.speaker?.lowercased())!
                    
                    conversations.append(lastConversation!)
                }
            }
            tableView.reloadData()
            print("tried to reload")
        }
        
    }
}

// Get column function
extension Array where Element : Collection {
    func getColumn(column : Element.Index) -> [ Element.Iterator.Element ] {
        return self.map { $0[ column ] }
    }
}

class ConversationCell: UITableViewCell
{
    // MARK: - IBOutlets

    @IBOutlet weak var conversation: UILabel!
    @IBOutlet weak var people: UILabel!
    @IBOutlet weak var time: UILabel!

    // Define each cell programmatically
    func populateItem (conversation: [String]) {
        
        print(conversation)
        self.conversation.text = conversation[0]
        self.people.text = conversation[1]
        self.time.text = conversation[2]
    }
}


extension FilterViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("convesration!!!!")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        
        let conversation = conversations[indexPath.row]
        print(conversation)
        print("conversation!!")
        cell.populateItem(conversation: conversation)
        
        // Rotate the cell if seraching
        if (!search) {
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)

        } else {
            cell.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        // Change background color to white always, even when selected for selection mode
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white
        cell.selectedBackgroundView = backgroundView

        return cell
    }
    
    // Default table view height
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0 // You can set any other value
    }
    
    // NOT ALLOW DELETION
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    // MARK - SEARCH BAR
    // Implement the search bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchRecordings(search: searchText.lowercased().stripped.components(separatedBy: " "))

    }
    
    // Dismiss the search bar when done.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
    }
    
    // Search function
    func searchRecordings(search: [String]){

        print(search)
        
        if search != [""] {
            self.search = true
            
            var tempConversations = [[String]]()
            for conversation in conversations {
                print(conversation)
                
                for word in search {
                    if (conversation[3].contains(word) || conversation[4].contains(word))  && !tempConversations.contains(conversation) {
                        tempConversations.append(conversation)
                    }
                }
            }
            
            conversations = tempConversations
            self.tableView.transform = CGAffineTransform(scaleX: 1, y: 1)
            print(tempConversations)
            tableView.reloadData()
            
        } else {
            self.search = false
            getConversations()
        }
    }

}



