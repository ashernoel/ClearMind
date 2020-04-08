//
//  ProfileViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/8/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//
// The main function of this view controller is to make a BEAUTIFUL profile page.
import SafariServices
import FirebaseAuth

class ProfileCell: UITableViewCell
{
    // MARK: - IBOutlets
    @IBOutlet weak var photoContainer: UIView!
    @IBOutlet weak var itemButton: UIButton!
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet var itemDescription: UILabel!
    @IBOutlet var backgroundImage: UIImageView!
    
    // Define each cell programmatically
    func populateItem (entry: [String]) {
        itemTitle.text = entry[0]
        itemDescription.text = entry[1]
        
        // Add a shadow to the overall container
        photoContainer.layer.cornerRadius = 10
        photoContainer.layer.cornerRadius = 10
        photoContainer.layer.shadowOpacity = 0.35
        photoContainer.layer.shadowRadius = 7
        photoContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        photoContainer.layer.shadowColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 30/255.0, alpha: 1).cgColor
        
        // Add a slight shadow to the title
        itemTitle.layer.shadowOffset = CGSize(width: 0, height: 0)
        itemTitle.layer.shadowOpacity = 1
        itemTitle.layer.shadowRadius = 6
        itemTitle.shadowColor = UIColor.black
        
        // Put the appropriate photo in each cell
        if entry[0] == "Logout" {
            
            photoContainer.backgroundColor = UIColor.red
            backgroundImage.image = UIImage(named:"logoutPhoto")
            
        } else if entry[0] == "Settings" {
            
            photoContainer.backgroundColor = UIColor.green
            backgroundImage.image = UIImage(named:"settingsPhoto")
            
        } else if entry[0] == "Learn More" {
            
            photoContainer.backgroundColor = UIColor.yellow
            backgroundImage.image = UIImage(named:"learnMorePhoto")
        }
    }
}

// This view controller will make the cells
//
class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    // The text for the page
    var profileInformation = [["Logout", "Change account"], ["Settings", "Change preferences"], ["Learn More", "View on Github"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    // Remove the navigation bar from the profile page
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
}

// The table view functions are standard
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return profileInformation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
   
        let entry = profileInformation[indexPath.row]
        cell.populateItem(entry: entry)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        // Add different functions to the buttons in each cell depending on the title
        if entry[0] == "Logout" {
            cell.itemButton.addTarget(self, action: #selector(self.logout), for: .touchUpInside)
        } else if entry[0] == "Learn More" {
            cell.itemButton.addTarget(self, action: #selector(self.learnMore), for: .touchUpInside)
        } else if entry[0] == "Settings" {
            cell.itemButton.addTarget(self, action: #selector(self.settingsSegue), for: .touchUpInside)
        }
        
        return cell
    }
    
    // Logout and then segue back to the initial view controller for the login sequence
    @objc func logout () {
        
        // Sign user out
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
         
        performSegue(withIdentifier: "logoutSegue", sender: self)
    }
    
    // Open github
    @objc func learnMore() {
          guard let url = URL(string: "https://www.github.com/ashernoel/ClearMind") else {
              return
          }
          
          let safariVC = SFSafariViewController(url: url)
          safariVC.delegate = self
          present(safariVC, animated: true, completion: nil)
          
      }
    
    // Navigate to a different view controller
    @objc func settingsSegue() {
        performSegue(withIdentifier: "settingsSegue", sender: self)
    }
}
