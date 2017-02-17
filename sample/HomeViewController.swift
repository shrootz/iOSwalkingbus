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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        // let serialQueue = DispatchQueue(label: "dumbass")
        var userID = ""
        var userName = ""
        
        FIRDatabase.database().reference().child("parents/\(FIRAuth.auth()!.currentUser!.uid)/").observeSingleEvent(of: .value, with: {(snap) in
            self.parent_auth_id = (FIRAuth.auth()?.currentUser?.uid)!
            userName = (FIRAuth.auth()?.currentUser?.displayName)!
            self.parent_location = String(format: "parents/%@/", self.parent_auth_id)
            print (self.parent_location)
            if snap.exists(){
                //Your user already has a username
                print("i fucking exist in this goddamn database")
            }else{
                //You need to set the user's name and the the required segue
                print("need to add")
                self.ref.child(self.parent_location).child("name").setValue(userName as String!)
            }
        })
        
        /*
         serialQueue.sync {
         print("gfdi")
         //let query = FIRDatabase.database().reference(withPath: "parents/").queryEqual(toValue: userID, childKey: userName)
         //print(query)
         self.ref.child("/parents").observeSingleEvent(of: .value, with: { (snapshot) in
         print("help")
         if snapshot.hasChild(userID as String!){
         print("i already found myself in the database")
         } else{
         self.ref.child(self.parent_location).setValue(userName as String!)
         print("added myself to the database")
         }
         })
         }
         
         serialQueue.sync {
         FIRAuth.auth()!.addStateDidChangeListener { auth, user in
         guard user != nil else { return }
         userID = (FIRAuth.auth()?.currentUser?.uid)!
         userName = (FIRAuth.auth()?.currentUser?.displayName)!
         self.parent_location = String(format: "parents/%@/", userID)
         print (self.parent_location)
         }
         }
         */
        /*let firstGroup = DispatchGroup.init()
         var userID = ""
         var userName = ""
         
         firstGroup.enter()
         FIRAuth.auth()!.addStateDidChangeListener { auth, user in
         guard user != nil else { return }
         userID = (FIRAuth.auth()?.currentUser?.uid)!
         userName = (FIRAuth.auth()?.currentUser?.displayName)!
         self.parent_location = String(format: "parents/%@/", userID)
         print (self.parent_location)
         
         }
         
         firstGroup.leave()
         firstGroup.notify(queue: DispatchQueue.main, execute: {
         let secondGroup = DispatchGroup.init()
         secondGroup.enter()
         print("enters the first group notification")
         self.ref.child("parents/").observeSingleEvent(of: .value, with: { (snapshot) in
         print("help")
         if snapshot.hasChild(userID as String!){
         print("i already found myself in the database")
         } else{
         self.ref.child(self.parent_location).setValue(userName as String!)
         print("added myself to the database")
         }
         })
         secondGroup.leave()
         secondGroup.notify(queue: DispatchQueue.main) {
         print("All the loading is fin")
         }
         } ) */
        
        
    }
    
    /*
     let ref = FIRDatabase.database().reference(withPath: "parents/").queryEqual(toValue: userID, childKey: userName)
     ref.observeSingleEvent(of: .childAdded, with: { snapshot in
     print(snapshot)
     })
     }
     */
    
    /*self.ref?.child("parents/").observeSingleEvent(of: .value, with: { (snapshot) in
     for item in snapshot.children {
     let val = (item as AnyObject).value as String
     if(val == userID){
     print("i already found myself in the database")
     return;
     }
     }
     print("added myself to the database")
     })
     */
    
    
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
        }
    }
    
}
