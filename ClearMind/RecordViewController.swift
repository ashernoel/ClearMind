//
//  RecordViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/6/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//

import UIKit
import Firebase

class RecordViewController: UIViewController {
    
    var db: Firestore!

    let user = Auth.auth().currentUser

 
    @IBOutlet weak var textField: UITextField!
    @IBAction func saveButton(_ sender: Any) {
         
        
        addToBothCollections(message: textField.text ?? "(empty)", conversation: "PLACEHOLDER_CONVERSATION", speaker: "PLACEHOLDER_SPEAKER", time: Timestamp(date: Date()), time_seconds: Timestamp(date: Date()).seconds)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START setup]
        let settings = FirestoreSettings()

        Firestore.firestore().settings = settings
        
        // [END setup]
        db = Firestore.firestore()
    }
    
    func addToBothCollections(message: String, conversation: String, speaker: String, time: Timestamp, time_seconds: Int64) {
        
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
    
}

extension String {

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        return self.filter {okayChars.contains($0) }
    }
}
