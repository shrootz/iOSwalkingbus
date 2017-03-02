//
//  HomeViewController.swift
//  sample
//
//  Created by Subie Madhavan on 2/10/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    var parent_user: Parent!
    var ref: FIRDatabaseReference!
    var parent_location: String!
    var parent_auth_id: String!
    var userName = ""
    var email = ""
    var photoUrl = ""
    var phoneNumber = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        
        FIRDatabase.database().reference().child("users/\(FIRAuth.auth()!.currentUser!.uid)/").observeSingleEvent(of: .value, with: {(snap) in
            self.parent_auth_id = (FIRAuth.auth()?.currentUser?.uid)!
            self.userName = (FIRAuth.auth()?.currentUser?.displayName) as String!
            self.email = FIRAuth.auth()?.currentUser?.email as String!
            self.photoUrl = FIRAuth.auth()?.currentUser?.photoURL?.absoluteString as String!
            self.parent_location = String(format: "users/%@/", self.parent_auth_id)
            print (self.parent_location)
            if snap.exists(){
                self.userName = (snap.childSnapshot(forPath: "displayName").value as? String)!
                self.email = (snap.childSnapshot(forPath: "email").value as? String)!
                self.photoUrl = (snap.childSnapshot(forPath: "photoUrl").value as? String)!
                self.phoneNumber = (snap.childSnapshot(forPath: "phone").value as? String)!
                
                print("User was found in database. Loading...")
            }else{
                print("Adding User to Database...")
                self.ref.child(self.parent_location).setValue([
                    "displayName": self.userName,
                    "email": self.email,
                    "photoUrl": self.photoUrl,
                    "phone": self.phoneNumber
                    ])
            }
        })
        
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EnterParent" {
            let studentNavController = segue.destination as! UINavigationController
            let studentViewController = studentNavController.topViewController as! StudentTableViewController
            studentViewController.ref = ref
            studentViewController.parent_location = parent_location
            studentViewController.parent_auth_id = parent_auth_id
        } else if segue.identifier == "editUser" {
            let editUserViewController = segue.destination as! EditUserViewController
            editUserViewController.ref = ref
            editUserViewController.parent_location = parent_location
            editUserViewController.parent_auth_id = parent_auth_id
            editUserViewController.name = userName
            editUserViewController.email = email
            editUserViewController.photoUrl = photoUrl
            print(self.photoUrl)
            editUserViewController.phone = phoneNumber
        }
    }
    
}
