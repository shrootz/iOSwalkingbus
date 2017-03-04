//
//  HomeScreenViewController.swift
//  sample
//
//  Created by Subie Madhavan on 3/3/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class HomeScreenViewController: UIViewController, GIDSignInUIDelegate {

    //MARK: - Outlets
    @IBOutlet weak var userModeButtons: UIStackView!
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    //MARK: - Variables
    var appUser: User!
    
    
    //MARK: - Actions
    @IBAction func signOut(_ sender: UIButton) {
        do{
            try FIRAuth.auth()?.signOut()
        } catch{
            print("Error while signing out")
        }
        
    }

    
    //MARK: - Load
    override func viewDidLoad() {
        super.viewDidLoad()
        //Assume not signed in, show only google sign in button
        self.initButtons()
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                //After sign in hide sign in button and show other buttons
                self.signInButton.isHidden = true
                self.userModeButtons.isHidden = false
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.retrieveUserInfo()
            }
            else{
                self.initButtons()
                GIDSignIn.sharedInstance().uiDelegate = self
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be re//created.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GIDSignIn.sharedInstance().uiDelegate = self

    }
    
    //Mark: - Functions
    func initButtons(){
        //set button state for signed out user
        self.signInButton.isHidden = false
        self.userModeButtons.isHidden = true
        self.editButtonItem.isEnabled = false
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func retrieveUserInfo() {
        let user = FIRAuth.auth()!.currentUser!
        let userAuthId = user.uid
        var userName = ""
        var email = ""
        var phoneNumber = ""
        var photoUrl = ""
        let databaseLocation = String(format: "users/%@/", userAuthId)
        FIRDatabase.database().reference().child(databaseLocation).observeSingleEvent(of: .value, with: {(userSnap) in
            if(userSnap.exists()) {
                print("User was found in database. Loading...")
                userName = (userSnap.childSnapshot(forPath: "displayName").value as? String)!
                email = (userSnap.childSnapshot(forPath: "email").value as? String)!
                photoUrl = (userSnap.childSnapshot(forPath: "photoUrl").value as? String)!
                phoneNumber = (userSnap.childSnapshot(forPath: "phone").value as? String)!
            } else {
                print("Adding user to database...")
                userName = user.displayName ?? ""
                email = user.email ?? ""
                if let myPhotoUrl = user.photoURL {
                    photoUrl = myPhotoUrl.absoluteString
                }

                //Updating database 
                FIRDatabase.database().reference().child(databaseLocation).setValue([
                    "displayName": userName,
                    "email": email,
                    "photoUrl": photoUrl,
                    "phone": phoneNumber
                    ])
            }
            
            self.appUser = User(userAuthId: userAuthId, name: userName, phoneNumber: phoneNumber, email: email, photoUrl: photoUrl)
        })
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "enterParent" {
            //Entering parent mode, showing parents children
            let studentNavController = segue.destination as! UINavigationController
            let studentViewController = studentNavController.topViewController as! StudentTableViewController
            studentViewController.parentAuthId = appUser.userAuthId
        } else if segue.identifier == "editUser" {
            //Editing user information
            if let editUserViewController = segue.destination as? EditUserViewController {
                editUserViewController.appUser = appUser
            }
        }
        // TODO: Add entrance to chaperone mode
    }


}
