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
    var db: Firestore!
    let user = Auth.auth().currentUser
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var lastDocumentSnapshot: DocumentSnapshot!
    var fetchingMore = false
    var search = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: UIApplication.willEnterForegroundNotification, object: nil)

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Remove the navigation bar
        self.navigationController?.isNavigationBarHidden = true
        // Make sure all data correct
        recordings.removeAll()
        paginateData()
    }
    @IBAction func filterSegue(_ sender: Any) {
        performSegue(withIdentifier: "filterSegue", sender: self)
    }
    
    @objc func loadData() {
         // Call getDateTimeFromServer()
        paginateData()
    }
    

}

struct Recording {
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
         // Update the table using a mutation
        
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
        
        if (!search) {
            cell.transform = CGAffineTransform(scaleX: 1, y: -1)

        } else {
            cell.transform = CGAffineTransform(scaleX: 1, y: 1)
        }

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
        var query = buildQueryWithDates()
        print("Query after building with dates")
        print(query)

        if recordings.isEmpty {
            query = query.order(by: "time", descending: true).limit(to: 10)
            print("First 10 recordings loaded")
        } else {
            query = query.order(by: "time", descending: true).start(afterDocument: lastDocumentSnapshot).limit(to: 10)
            print("Next 10 recordings loaded")
        }

        query.getDocuments { (snapshot, err) in
            if let err = err {
                print("\(err.localizedDescription)")
            } else if snapshot!.isEmpty {
                self.fetchingMore = true
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

            
            guard let messageID = recordings[indexPath.row].messageID else {
                return
            }
            db.collection("users").document(user!.uid).collection("messages").whereField("messageID", isEqualTo: messageID).getDocuments() { (querySnapshot, err) in
                if let err = err {
                  print("Error getting documents: \(err)")
                    
                } else {
                  for document in querySnapshot!.documents {
                    document.reference.delete()
                    
                    print("Document deleted")
                    self.recordings.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)

                  }
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
        print(search)
        
            let query = buildQueryWithDates()
            query.whereField("search_insensitive", arrayContainsAny: search).getDocuments{ (querySnapshot, err) in
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
    
    func buildQueryWithDates() -> Query {
        
        let db = Firestore.firestore()
        let user = Auth.auth().currentUser

        // BASE query
        let messagesRef = db.collection("users").document(user!.uid).collection("messages")
        
        var query: Query!
        var updated = false
        
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
                    
                    if updated {
                        query = query.whereField("time_seconds", isGreaterThan: (myData["start_time"] as! Timestamp).seconds)
                    } else {
                        query = messagesRef.whereField("time_seconds", isGreaterThan: (myData["start_time"] as! Timestamp).seconds)
                    }
                    
                    updated = true
                }
            }
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
                    
                    print((myData["end_time"] as! Timestamp).seconds)
                    //query = query.whereField("time", isLessThan: myData["end_time"]!)
                    if updated {
                        query = query.whereField("time_seconds", isLessThan: (myData["end_time"] as! Timestamp).seconds)
                    } else {
                        query = messagesRef.whereField("time_seconds", isLessThan: (myData["end_time"] as! Timestamp).seconds)
                    }
                    
                    updated = true
                }
            }
        }
        
        print(updated)
        if updated {
            return query
        } else {
            return messagesRef
        }
        
    }
    
    
}


