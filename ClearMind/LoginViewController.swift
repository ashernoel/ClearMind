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
