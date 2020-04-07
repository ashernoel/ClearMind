//
//  ViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 4/6/20.
//  Copyright © 2020 Asher Noel. All rights reserved.
//

import UIKit
import FirebaseUI


class LoginViewController: UIViewController, FUIAuthDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Check to see if the user is already logged in
        if Auth.auth().currentUser != nil {
            
            performSegue(withIdentifier: "signedIn", sender: nil)
            
        } else {
        
            let authUI = FUIAuth.defaultAuthUI()
            authUI?.delegate = self
            
            let providers: [FUIAuthProvider] = [
              FUIGoogleAuth(),
              FUIFacebookAuth()
            ]
            authUI?.providers = providers
            
            let authViewController = authUI!.authViewController()
            authViewController.modalPresentationStyle = .fullScreen
            self.present(authViewController, animated: true, completion: nil)
            
        }
        
    }

    // Handle SIGN IN EVENT
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        performSegue(withIdentifier: "signedIn", sender: nil)
        
        // Check to see if the user is in the database.
        // If the user is new, add them!
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user!.uid)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Do nothing if the user already exists
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                print("User already exists")
                
            } else {
                // If the user does not yet exist
                docRef.setData([
                    "time_joined" : Timestamp(date: Date())]) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("Document successfully written!")
                    }
                }
            }
        }
        
        print(user!.uid)
        print("Tried to add!")
    }

}

// Necessary function for GOOGLE and FACEBOOK login
func application(_ app: UIApplication, open url: URL,
                 options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
    let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String?
  if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
    return true
  }
  // other URL handling goes here.
  return false
}

// Remove the "Cancel" button from the firebase UI
extension FUIAuthBaseViewController{
  open override func viewWillAppear(_ animated: Bool) {
    self.navigationItem.leftBarButtonItem = nil
  }
}
