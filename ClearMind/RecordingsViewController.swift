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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        tableView.allowsSelection = false
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
         
         // Update the table using a mutation
        let ref = db.collection("users").document(user!.uid).collection("messages").document("messageID")

        // Set the "capital" field of the city 'D
        ref.updateData([
            "message": message.text ?? ""
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
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
        return cell
    }
    
    // If the UITextView is multiple lines, then the table view should adjust its height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return UITableView.automaticDimension
    }
    
    // Default table view height
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {

        return 200.0 // You can set any other value, it's up to you
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

        var query: Query!
        let user = Auth.auth().currentUser

        if recordings.isEmpty {
            query = db.collection("users").document(user!.uid).collection("messages").order(by: "time").limit(to: 10)
            print("First 10 recordings loaded")
        } else {
            query = db.collection("users").document(user!.uid).collection("messages").order(by: "time").start(afterDocument: lastDocumentSnapshot).limit(to: 4)
            print("Next 10 recordings loaded")
        }

        query.getDocuments { (snapshot, err) in
            if let err = err {
                print("\(err.localizedDescription)")
            } else if snapshot!.isEmpty {
                self.fetchingMore = false
                return
            } else {
                let newRecordings = snapshot!.documents.compactMap({Recording(dictionary: $0.data())})
                self.recordings.append(contentsOf: newRecordings)

                //
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.tableView.reloadData()
                    self.fetchingMore = false
                })

                self.lastDocumentSnapshot = snapshot!.documents.last
            }
        }
    }
    
    // editing check
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    // editing action
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            guard let messageID = recordings[indexPath.row].messageID else {
                return
            }
            db.document(messageID).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
        }
    }
    
    // TODO: SEARCH BAR
    
    // Implement the search bar and check for the empty string case.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText != "" {
        } else {
        }


    }
    
    // Dismiss the search bar when done.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
    }
    
    
}



