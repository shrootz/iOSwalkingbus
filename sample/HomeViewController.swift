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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        
        FIRAuth.auth()!.addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            let userID = FIRAuth.auth()?.currentUser?.uid
            let userName = FIRAuth.auth()?.currentUser?.displayName
            self.parent_location = String(format: "parents/%@/", userID!)
            print (self.parent_location)
            self.ref.child(self.parent_location).setValue(userName)
            print("added myself to the database")
        }
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
        }
    }
    
}
