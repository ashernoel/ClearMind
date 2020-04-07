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

        // Add the message AND generate an ID for it with proper error handling.
        var ref: DocumentReference? = nil
        ref = db.collection("users").document(user!.uid).collection("messages").addDocument(data: [
            "message" : textField.text ?? "(empty)",
            "conversation" : "PLACEHOLDER_CONVERSATION", // User can MANUALLY set/EDIT this later
            "speaker" : "PLACEHOLDER_SPEAKER", // PYTHON MLKIT should give this
            "time" : Timestamp(date: Date()),
            "messageID" : ref?.documentID
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

