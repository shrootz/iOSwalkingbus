//
//  EditStudentTableViewController.swift
//  sample
//
//  Created by Subie Madhavan on 2/5/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import os.log
import Firebase

class EditStudentTableViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var student_image: UIImageView!
    @IBOutlet weak var full_name: UITextField!
    @IBOutlet weak var school_name: UITextField!
    @IBOutlet weak var student_notes: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var monday_am: UIButton!
    @IBOutlet weak var monday_pm: UIButton!
    @IBOutlet weak var tuesday_am: UIButton!
    @IBOutlet weak var tuesday_pm: UIButton!
    @IBOutlet weak var wednesday_am: UIButton!
    @IBOutlet weak var wednesday_pm: UIButton!
    @IBOutlet weak var thursday_am: UIButton!
    @IBOutlet weak var thursday_pm: UIButton!
    @IBOutlet weak var friday_am: UIButton!
    @IBOutlet weak var friday_pm: UIButton!
    
    
    
    var student: Student?
    var coordinates : [String:[Double]] = [:]
    var names : [String:String] = [:]
    var ref: FIRDatabaseReference?
    var parent_auth_id: String?
    var student_pointer: String?
    
    @IBAction func browseForImage(_ sender: UIButton) {
        // Hide the keyboard.
        full_name.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
        /*let isPresentingInAddStudentMode = presentingViewController is UINavigationController
         
         if isPresentingInAddStudentMode {
         dismiss(animated: true, completion: nil)
         }
         else {
         navigationController!.popViewController(animated: true)
         }*/
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        // The info dictionary contains multiple representations of the image, and this uses the original.
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Set photoImageView to display the selected image.
        student_image.image = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Handle the text field’s user input through delegate callbacks.
        full_name.delegate = self
        if let student = student {
            navigationItem.title = student.name
            full_name.text   = student.name
            school_name.text = student.school
            student_notes.text = student.notes
            student_image.image = student.photo
            student_pointer = student.database_pointer
            coordinates = student.schedule_dictionary_coordinates
            names = student.schedule_dictionary_names
            if let val = student.schedule_dictionary_names["monday_am"] {
                monday_am.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["monday_pm"] {
                monday_pm.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["tuesday_am"] {
                tuesday_am.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["tuesday_pm"] {
                tuesday_pm.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["wednesday_am"] {
                wednesday_am.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["wednesday_pm"] {
                wednesday_pm.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["thursday_am"] {
                thursday_am.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["thursday_pm"] {
                thursday_pm.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["friday_am"] {
                friday_am.setTitle(val, for: .normal)
            }
            
            if let val = student.schedule_dictionary_names["friday_pm"] {
                friday_pm.setTitle(val, for: .normal)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if sender as AnyObject? === saveButton {
            print("save button tapped for the prepare")
            let name = full_name.text ?? ""
            let school = school_name.text ?? ""
            let notes = student_notes.text ?? ""
            let photo = student_image.image
            
            if(student_pointer == nil){
                let new_child = self.ref?.child("/children/").childByAutoId()
                let parents_children = "parents/" +  self.parent_auth_id! + "/children"
                self.ref?.child(parents_children).childByAutoId().setValue((new_child?.key)!)
                let parentarray: [String: String] =  [self.parent_auth_id! : "1"]
                
                new_child?.setValue([
                    "name": name,
                    "school": school,
                    "notes": notes,
                    "bluetooth":"11:11:11:11:11:11",
                    "status":"lost",
                    "parents":parentarray
                    ])
                student = Student(name: name, photo: photo, school: school, notes: notes, schedule_dictionary_coordinates: coordinates, schedule_dictionary_names: names, database_pointer: (new_child?.key)!)
            }
            else{
                let existing_child = self.ref?.child("/children/").child(student_pointer!)
                let parentarray: [String: String] =  [self.parent_auth_id! : "1"]
                existing_child?.setValue([
                    "name": name,
                    "school": school,
                    "notes": notes,
                    "bluetooth":"11:11:11:11:11:11",
                    "status":"lost",
                    "parents":parentarray
                    ])
                student = Student(name: name, photo: photo, school: school, notes: notes, schedule_dictionary_coordinates: coordinates, schedule_dictionary_names: names, database_pointer:student_pointer!)
            }
        }
            
        else if sender as AnyObject? === monday_am {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["monday_am"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
            
        }
        else if sender as AnyObject? === monday_pm {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["monday_pm"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
            
        }
        else if sender as AnyObject? === tuesday_am {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["tuesday_am"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
            
        }
        else if sender as AnyObject? === tuesday_pm {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["tuesday_pm"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
        }
        else if sender as AnyObject? === wednesday_am {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["wednesday_am"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
        }
        else if sender as AnyObject? === wednesday_pm {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["wednesday_pm"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
        }
        else if sender as AnyObject? === thursday_am {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["thursday_am"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
        }
        else if sender as AnyObject? === thursday_pm {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["thursday_pm"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
        }
        else if sender as AnyObject? === friday_am {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["friday_am"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
        }
        else if sender as AnyObject? === friday_pm {
            let mapViewController = segue.destination as! MapViewController
            if let val = coordinates["friday_pm"]{
                mapViewController.latitude = val[0]
                mapViewController.longitude = val[1]
            }
        }
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        navigationItem.title = textField.text
    }
    
    // MARK: - Table view data source
    /*
     override func numberOfSections(in tableView: UITableView) -> Int {
     // #warning Incomplete implementation, return the number of sections
     return 0
     }
     
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     // #warning Incomplete implementation, return the number of rows
     return 0
     }
     */
    /*
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
     
     // Configure the cell...
     
     return cell
     }
     */
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
}
