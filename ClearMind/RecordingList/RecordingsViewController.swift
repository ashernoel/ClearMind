//
//  RecordingsViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/7/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//

import UIKit
import Firebase

// We want a table view with MESSAGES sorted by TIME and CONVERSATION HEADINGS
class RecordingsViewController: UIViewController, UISearchBarDelegate {
    
    var recordings = [Recording]()
    var db = Firestore.firestore()
    let user = Auth.auth().currentUser
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var lastDocumentSnapshot: DocumentSnapshot!
    var fetchingMore = false
    var search = false
    var messagesRef: CollectionReference!
    
    @IBOutlet weak var selectButtonOutlet: UIButton!
    @IBOutlet weak var filterButtonOutlet: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var selectButton2: UIButton!
    
    @IBAction func selectButton(_ sender: Any) {
        tableView.setEditing(true, animated: true)
        //tableView.reloadData()
        selectButton2.isHidden = true
        filterButtonOutlet.isHidden = true
        
        editButton.isHidden = false
        deleteButton.isHidden = false
        exportButton.isHidden = false
        cancelButton.isHidden = false
        
        cancelButton.addTarget(self, action: #selector(exitSelectMode), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteSelected), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editSelected), for: .touchUpInside)
        exportButton.addTarget(self, action: #selector(exportSelected), for: .touchUpInside)

    }
    
    @objc func exitSelectMode () {
        tableView.setEditing(false, animated: true)
        //tableView.reloadData()
        editButton.isHidden = true
        deleteButton.isHidden = true
        exportButton.isHidden = true
        cancelButton.isHidden = true
        
        selectButton2.isHidden = false
        filterButtonOutlet.isHidden = false
    }
    
    @objc func deleteSelected () {
        
        // Delete the selected rows
        if let selectedRows = tableView.indexPathsForSelectedRows {
            // Remove from backend
            var items = [Recording]()
            for indexPath in selectedRows  {
                items.append(recordings[indexPath.row])
                deleteEntryFromBOTHCollections(indexPath: indexPath)
            }
            // Remove from recordings[]
            for item in items {
                if let index = recordings.firstIndex(of: item) {
                    recordings.remove(at: index)
    
                }
            }
            // Update table view
            tableView.beginUpdates()
            tableView.deleteRows(at: selectedRows, with: .automatic)
            tableView.endUpdates()
            
        }
    }
    
    @objc func editSelected () {
        let alert = UIAlertController(title: "Edit", message: "Apply properties to all messages", preferredStyle: .alert)
        
        
        //adding textfields to our dialog box
        alert.addTextField { (textField) in
            textField.placeholder = "Speaker (optional)"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Conversation (optional)"
        }
        
       
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
            if let textField = alert?.textFields?[0], let speaker = textField.text {
                print("User text: \(speaker)")
                
                // If the user inputed something, then mutate all of the rows
                if speaker != "" {
                    self.applyEdits (fieldValue: "speaker", value: speaker)
                }
            }

            if let textField = alert?.textFields?[1], let conversation = textField.text {
                print("User text 2: \(conversation)")
                
                // If the user inputed something, then mutate all of the rows
                if conversation != "" {
                    self.applyEdits (fieldValue: "conversation", value: conversation)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
        //finally presenting the dialog box
        self.present(alert, animated: true, completion: nil)
        // Push edits to the selected rows
    }
     
    @objc func exportSelected () {
        // Implement exports later
    }
    
    // Run a basic mutation on a STRING field value
    func applyEdits (fieldValue: String, value: String) {
        
        // Apply edits to selected rows
            if let selectedRows = tableView.indexPathsForSelectedRows {
                // Apply edits to backend
                var items = [Recording]()
                print(fieldValue)
                print(value)
                print(selectedRows)
                print(items)
                for indexPath in selectedRows  {
                    print(indexPath)
                    print(recordings)
                    items.append(recordings[indexPath.row])
                    runSimpleMutation(indexPath: indexPath, fieldValue: fieldValue, value: value)
                }
                // Edit recordings
                for item in items {
                    if let index = recordings.firstIndex(of: item) {
                        if fieldValue == "conversation" {
                            recordings[index].conversation = value
                        } else if fieldValue == "speaker" {
                            recordings[index].speaker = value
                        } else {
                            print("unkown fieldValue")
                        }
                            
                    }
                }
                // Update only the correct cells in the table view
                tableView.beginUpdates()
                tableView.reloadRows(at: selectedRows, with: .automatic)
                tableView.endUpdates()
                
            }
    }
    
    // Run a mutation on BOTH collections
    func runSimpleMutation (indexPath: IndexPath, fieldValue: String, value: String) {

        var flag: Int
        if fieldValue == "conversation" {
            flag = 0
        } else if fieldValue == "speaker" {
            flag = 1
        } else {
            flag = 2
        }
        
        guard let messageID = self.recordings[indexPath.row].messageID else {
            return
        }
        
        // Update BOTH tables
        db.collection("users").document(user!.uid).collection("messages_filtered").whereField("messageID", isEqualTo: messageID).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    let myData = document.data()
                    var searchable = myData["search_insensitive"] as! [String]
                    searchable[flag] = value
                    
                    document.reference.updateData([
                        fieldValue: value,
                       "search_insensitive" : searchable
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                }
            }
        }
        db.collection("users").document(user!.uid).collection("messages").whereField("messageID", isEqualTo: messageID).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    
                    let myData = document.data()
                    var searchable = myData["search_insensitive"] as! [String]
                    searchable[flag] = value
                    
                    document.reference.updateData([
                        fieldValue: value,
                       "search_insensitive" : searchable
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        messagesRef = db.collection("users").document(user!.uid).collection("messages_filtered")
    
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        editButton.isHidden = true
        deleteButton.isHidden = true
        exportButton.isHidden = true
        cancelButton.isHidden = true
        
        // Allow multiple selection in "Select" mode
        tableView.allowsMultipleSelectionDuringEditing = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Remove the navigation bar
        self.navigationController?.isNavigationBarHidden = true
        // Make sure all data correct
        recordings.removeAll()
        paginateData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove content from search bar when leaving
        searchBar.text = ""
        search = false
        
    }
    
    @IBAction func filterSegue(_ sender: Any) {
        performSegue(withIdentifier: "filterSegue", sender: self)
    }
    
    @objc func loadData() {
         // Call getDateTimeFromServer()
        paginateData()
    }
    

}

struct Recording: Equatable {
    var message : String?
    var conversation : String?
    var speaker : String?
    var time : Timestamp?
    var messageID: String?
    
    init?(dictionary: [String : Any]) {
        self.message = dictionary["message"] as? String
        self.conversation = dictionary["conversation"] as? String
        self.speaker = dictionary["speaker"] as? String
        self.time = dictionary["time"] as? Timestamp
        self.messageID = dictionary["messageID"] as? String
    }
}

class MessageCell: UITableViewCell, UITextViewDelegate
{
    // MARK: - IBOutlets
    
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var speaker: UILabel!
    @IBOutlet weak var conversation: UILabel!
    @IBOutlet weak var time: UILabel!
    
    var originalTimestamp: Timestamp?
    var messageID: String?
    
    let user = Auth.auth().currentUser
    let db = Firestore.firestore()
    // Define each cell programmatically
    func populateItem (recording: Recording) {
        
        createToolbar()
        message.delegate = self
            
        message.text = recording.message
        speaker.text = recording.speaker
        conversation.text = recording.conversation
        messageID = recording.messageID
        originalTimestamp = recording.time
  
        let df = DateFormatter()
        df.dateFormat = "MM-dd hh:mm:ss"
        time.text = df.string(from: (recording.time?.dateValue())!)
    }
    

    // This creates a toolbar and "Save" button when editing a recording
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
     
     // This updates the recording cell and there rest of the table view
     @objc func dismissKeyboard()
     {
         // Dismiss the keyboard
         message.endEditing(true)
        
        // Update searchable content
        let get_string = self.message.text ?? ""
        // STRING -> LIST OF WORDS
        let array_of_lowercase_words = get_string.lowercased().stripped.components(separatedBy: " ")
        let df = DateFormatter()
        df.dateFormat = "MMMM, yyyy"
        let conversation_lower = conversation.text!.lowercased()
        let speaker_lower = speaker.text!.lowercased()
        let date_lower = df.string(from: (originalTimestamp!.dateValue())).lowercased()
        let identifiers_lowercase = [conversation_lower, speaker_lower, date_lower]
        
        // Update BOTH tables
        db.collection("users").document(user!.uid).collection("messages_filtered").whereField("messageID", isEqualTo: messageID!).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                    document.reference.updateData([
                        "message": get_string,
                        "search_insensitive" : Array(Set(identifiers_lowercase + array_of_lowercase_words))
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                }
            }
        }
        db.collection("users").document(user!.uid).collection("messages").whereField("messageID", isEqualTo: messageID!).getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                    document.reference.updateData([
                        "message": get_string,
                        "search_insensitive" : Array(Set(identifiers_lowercase + array_of_lowercase_words))
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                }
            }
        }
    
     }
     
}


extension RecordingsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        let recording = recordings[indexPath.row]
        cell.populateItem(recording: recording)
        
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
    
    // If the UITextView is multiple lines, then the table view should adjust its height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // Default table view height
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0 // You can set any other value
    }
    
    // UITableViewCell Detete string
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    {
         return "✕"
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        //print("offsetY: \(offsetY) | contHeight-scrollViewHeight: \(contentHeight-scrollView.frame.height)")
        if offsetY > contentHeight - scrollView.frame.height - 50 {
            // Bottom of the screen is reached
            if !fetchingMore {
                paginateData()
            }
        }
    }
    
    // Paginates data
    func paginateData() {

        fetchingMore = true
        
        var query = messagesRef.whereField("time_seconds", isLessThan: (Timestamp(date: Date()).seconds))

        if self.recordings.isEmpty {
            query = query.order(by: "time_seconds", descending: true).limit(to: 10)
            print("First 10 recordings loaded")
        } else {
            query = query.order(by: "time_seconds", descending: true).start(afterDocument: self.lastDocumentSnapshot).limit(to: 10)
            print("Next 10 recordings loaded")
        }
        
        query.getDocuments { (snapshot, err) in
            if let err = err {
                print("\(err.localizedDescription)")
            } else if snapshot!.isEmpty {
                self.fetchingMore = true
                self.tableView.reloadData()
                
                return
            } else {
                    let newRecordings = snapshot!.documents.compactMap({Recording(dictionary: $0.data())})
                    self.recordings.append(contentsOf: newRecordings)
                    // If NOT searching, then list bottom up and do not accept clicks!
                if (!self.search) {
                        self.tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
                    }
                    self.tableView.allowsSelection = self.search
                
                    self.tableView.reloadData()
                    self.fetchingMore = false
                    self.lastDocumentSnapshot = snapshot!.documents.last
                
            }
        }
            
        
    }
    
    // ALLOW DELETION
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    // DELETE AN ENTRY ACTION
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
    
        
        if editingStyle == UITableViewCell.EditingStyle.delete {
            
            deleteEntryFromBOTHCollections(indexPath: indexPath)
            recordings.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // Delete from both collections
    func deleteEntryFromBOTHCollections(indexPath: IndexPath) {
        
        guard let messageID = self.recordings[indexPath.row].messageID else {
            return
        }
        
        // Remove an entry from the FILTERED collection
        db.collection("users").document(user!.uid).collection("messages_filtered").whereField("messageID", isEqualTo: messageID).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    document.reference.delete()
                }
            }
        }
        
        // Remove an entry from the ORIGINAL MESSAGES collection
        db.collection("users").document(user!.uid).collection("messages").whereField("messageID", isEqualTo: messageID).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    document.reference.delete()
                }
            }
        }
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

        fetchingMore = true
        if search != [""] {
            self.messagesRef.whereField("search_insensitive", arrayContainsAny: search).getDocuments{ (querySnapshot, err) in
                if let err = err {
                    print("\(err.localizedDescription)")
                    print("Test Error")
                } else {
                    if (querySnapshot!.isEmpty == false){
                        let searchedRecordings = querySnapshot!.documents.compactMap({Recording(dictionary: $0.data())})
                        self.recordings = searchedRecordings
                        self.search = true
                        self.tableView.transform = CGAffineTransform(scaleX: 1, y: 1)
                                
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.fetchingMore = true
                        }
                        print("found recordings!")
                    } else {
                        print("No recordings found")
                    }
                }
            }
        } else {
            recordings.removeAll()
            self.search = false
            paginateData()
        }
    }

}
