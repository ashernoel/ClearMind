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
         
        let user = Auth.auth().currentUser
        let df = DateFormatter()
        df.dateFormat = "MMMM, yyyy"

        let get_string = textField.text ?? ""

        // STRING -> LIST OF WORDS
        let array_of_lowercase_words = get_string.lowercased().stripped.components(separatedBy: " ")
        let identifiers_lowercase = ["PLACEHOLDER_CONVERSATION".lowercased(), "PLACEHOLDER_SPEAKER".lowercased(), df.string(from: Date()).lowercased()]
        
        // Add the message AND generate an ID for it with proper error handling.
        var ref: DocumentReference? = nil
        let newDocumentID = UUID().uuidString
        ref = db.collection("users").document(user!.uid).collection("messages").addDocument(data: [
            "message" : textField.text ?? "(empty)",
            "conversation" : "PLACEHOLDER_CONVERSATION", // User can MANUALLY set/EDIT this later
            "speaker" : "PLACEHOLDER_SPEAKER", // PYTHON MLKIT should give this
            "time" : Timestamp(date: Date()),
            "time_seconds" : Timestamp(date: Date()).seconds,
            "messageID" : newDocumentID,
            
            // Firestore only handles LOWERCASE and can only serach in arrays
            "search_insensitive" : Array(Set(identifiers_lowercase + array_of_lowercase_words))
            ]
        ) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START setup]
        let settings = FirestoreSettings()

        Firestore.firestore().settings = settings
        
        // [END setup]
        db = Firestore.firestore()
    }
    
}

extension String {

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        return self.filter {okayChars.contains($0) }
    }
}
