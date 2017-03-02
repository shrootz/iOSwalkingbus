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
    
    var ref: FIRDatabaseReference?
    var parent_location: String?
    var parent_auth_id: String?
    var name: String?
    var phone: String?
    var email: String?
    var photoUrl: String?
    var schoolDict: [UISwitch:UILabel] = [:]
    var mySchools:[String] = []
    var possibleSchools: [String:String] = [:]
    @IBOutlet weak var imageDisplay: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = false;
        nameField.text = name
        phoneField.text = phone
        emailField.text = email
        //get image here
        if let checkedUrl = URL(string: photoUrl!) {
            imageDisplay.contentMode = .scaleAspectFit
            downloadImage(url: checkedUrl)
        }
        
        //load schools
        self.ref?.child(parent_location!).child("schools_parent").observeSingleEvent(of: .value, with: {(snap1) in
            if (snap1.exists()) {
                for item in snap1.children.allObjects {
                    self.mySchools.append((item as AnyObject).value)
                }
            }
            
            FIRDatabase.database().reference().child("/school_names/").observeSingleEvent(of: .value, with: {(snap) in
                if snap.exists(){
                    let last_x = self.schoolLabel.frame.maxX + 25
                    var last_y = self.schoolLabel.frame.maxY
                    for item in snap.children.allObjects {
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
                        //mySwitch.addTarget(self, action: #selector())
                    }
                }
            })
        
        })
        

        
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadImage(url: URL) {
        print("Download Started")
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() { () -> Void in
                self.imageDisplay.image = UIImage(data: data)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func browseForImage(_ sender: UIButton) {
        // Hide the keyboard.
        nameField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Saving updated parent...")
        var schoolUpdates = [String:String]()
        for (toggle,label) in schoolDict {
            if(toggle.isOn) {
                schoolUpdates[possibleSchools[label.text!]!] = label.text
            }
        }
        self.ref?.child(self.parent_location!).updateChildValues([
            "displayName": self.nameField.text as Any,
            "email":self.emailField.text as Any,
            "phone":self.phoneField.text as Any])

        self.ref?.child(self.parent_location!).child("schools_parent").setValue(schoolUpdates)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    //override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    //}


}
