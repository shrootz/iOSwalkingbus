//
//  EditUserViewController.swift
//  sample
//
//  Created by Sneha Shrotriya on 3/1/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import Firebase

class EditUserViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Mark: - Outlets
    @IBOutlet weak var imageDisplay: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    //Mark: - Variables
    var appUser: User!
    var schoolDict: [UISwitch:UILabel] = [:]
    var mySchools:[String] = []
    var possibleSchools: [String:String] = [:]
    
    //MARK: - Load
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        self.navigationController?.navigationBar.isTranslucent = false;
        nameField.text = appUser.name ?? ""
        phoneField.text = appUser.phoneNumber ?? ""
        emailField.text = appUser.email ?? ""
        if let checkedUrl = URL(string: appUser.photoUrl!) {
            imageDisplay.contentMode = .scaleAspectFit
            downloadImage(url: checkedUrl)
        }
        
        loadSchools()
    }
    
    func loadSchools() {
        
        //Loading my schools
        print("Getting my schools...")
        let databaseReference = FIRDatabase.database().reference().child("users").child(appUser.userAuthId).child("schools_parent")
        databaseReference.observeSingleEvent(of: .value, with: {(mySchools) in
            if (mySchools.exists()) {
                for schoolEntry in mySchools.children.allObjects {
                    let schoolName = (schoolEntry as AnyObject).value as String
                    self.mySchools.append(schoolName)
                }
            }
            
            self.loadAllPossibleSchools()
        })
        
    }
    
    func loadAllPossibleSchools() {
        print("Getting all possible schools...")
        let databaseReference = FIRDatabase.database().reference().child("/school_names/")
        databaseReference.observeSingleEvent(of: .value, with: {(allSchools) in
            if allSchools.exists(){
                //add a toggle and label for all schools
                let last_x = self.schoolLabel.frame.maxX + 25
                var last_y = self.schoolLabel.frame.maxY
                for item in allSchools.children.allObjects {
                    let mySwitch = UISwitch(frame:CGRect(x: last_x, y: last_y + 5, width: 0, height: 0))
                    mySwitch.setOn(false, animated: false)
                    let myLabel = UILabel(frame:CGRect(x: last_x + 75, y: last_y + 5, width: 200, height: 21))
                    myLabel.text = (item as AnyObject).key
                    self.schoolDict[mySwitch] = myLabel
                    if (self.mySchools.contains(myLabel.text!)) {
                        mySwitch.setOn(true, animated: false)
                    }
                    self.possibleSchools[(item as AnyObject).key] = (item as AnyObject).value
                    last_y = mySwitch.frame.maxY
                    self.view.addSubview(mySwitch)
                    self.view.addSubview(myLabel)
                    mySwitch.addTarget(self, action: #selector(EditUserViewController.schoolSelected(_:)), for: UIControlEvents.valueChanged)
                }
            }
        })
        
    }
    
    func schoolSelected(_ mySwitch: UISwitch) {
        //if a school is selected require a parent to enter the passcode
        if mySwitch.isOn {
            //1. Create the alert controller.
            let alert = UIAlertController(title: "Verify", message: "Enter school passcode", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.text = ""
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                print("Text field: \(textField?.text)")
                let thisSchool = self.schoolDict[mySwitch]! as UILabel;
                let schoolName = thisSchool.text!
            FIRDatabase.database().reference().child("schools").child(self.possibleSchools[schoolName]!).child("users").child(self.appUser.userAuthId).setValue(["displayName":self.appUser.name,
                                                        "photoUrl":self.appUser.photoUrl,
                                                        "phone":self.appUser.phoneNumber,
                                                        "code":textField?.text]) { (error,ref) -> Void  in
                    if(error != nil){
                        mySwitch.isOn = false;
                        self.displayToastMessage(displayText: "Please contact school for passcode")
                    }
                }
    
                
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Functions
    func displayToastMessage(displayText: String) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.center.x-150, y : self.view.center.y, width: 300, height: 35))
        toastLabel.backgroundColor = UIColor.black
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = NSTextAlignment.center;
        self.view.addSubview(toastLabel)
        toastLabel.text = displayText
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            
            toastLabel.alpha = 0.0
            
        }, completion: nil)
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadImage(url: URL) {
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() { () -> Void in
                self.imageDisplay.image = UIImage(data: data)
            }
        }
    }
    
    //MARK: - Save
    func updateSchools() -> [String:String]{
        print("Saving updated user for schools")
        var schoolUpdates = [String:String]()
        for (toggle,label) in schoolDict {
            if let schoolName = label.text {
                let databaseReference = FIRDatabase.database().reference().child("schools").child(possibleSchools[schoolName]!).child("users").child(appUser.userAuthId)
                if(toggle.isOn) {
                    schoolUpdates[possibleSchools[schoolName]!] = schoolName
                    FIRDatabase.database().reference().child("schools").child(self.possibleSchools[schoolName]!).child("users").child(self.appUser.userAuthId).updateChildValues(["displayName":self.nameField.text as Any, "photoUrl":self.appUser.photoUrl as Any,"phone":self.phoneField.text as Any])
                } else {
                    databaseReference.removeValue()
                }
            }
            
        }
        return schoolUpdates
    }
    
    func updateUser(userSchoolUpdates: [String:String]) {
        //update user information
        print("Saving user updates...")
        let databaseReference = FIRDatabase.database().reference().child("users").child(appUser.userAuthId)
        databaseReference.updateChildValues([
            "displayName": self.nameField.text as Any,
            "email":self.emailField.text as Any,
            "phone":self.phoneField.text as Any])
        
        //overwrite previous school information for this user
        databaseReference.child("schools_parent").setValue(userSchoolUpdates)

    }
    
    // MARK: - Navigation
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let controller = viewController as? HomeScreenViewController {
            print("Saving updated user...")
            let userSchoolUpdates = updateSchools()
            var reverseSchoolUpdates: [String:String] = [:]
            for (key, val) in userSchoolUpdates { //to get the mapping as key, school name for local object
                reverseSchoolUpdates[val] = key
            }
            updateUser(userSchoolUpdates: userSchoolUpdates)
            self.appUser.update(name: nameField.text,phoneNumber: phoneField.text,email: emailField.text, schoolsParent:reverseSchoolUpdates)
            controller.appUser = self.appUser
        }
    }

}
