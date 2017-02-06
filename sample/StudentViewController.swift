//
//  ViewController.swift
//  sample
//
//  Created by Subie Madhavan on 10/26/16.
//  Copyright © 2016 seniordesign. All rights reserved.
//

import UIKit

class StudentViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var schoolNameTextField: UITextField!
    @IBOutlet weak var medicalInfoTextField: UITextField!
    @IBOutlet weak var studentPhoto: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var student: Student?
    // MARK: Action
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        // Hide the keyboard.
        nameTextField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func browseForImage(_ sender: UIButton) {
        // Hide the keyboard.
        nameTextField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        // The info dictionary contains multiple representations of the image, and this uses the original.
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Set photoImageView to display the selected image.
        studentPhoto.image = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
        
    }
 

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if sender as AnyObject? === saveButton {
            let name = nameTextField.text ?? ""
            let school = schoolNameTextField.text ?? ""
            let medical = medicalInfoTextField.text ?? ""
            let photo = studentPhoto.image
            //let photo = UIImage(named: "DefaultImage")!
            // Set the meal to be passed to MealTableViewController after the unwind segue.
            student = Student(name: name, photo: photo, school: school, notes: medical)
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddStudentMode = presentingViewController is UINavigationController
        
        if isPresentingInAddStudentMode {
            dismiss(animated: true, completion: nil)
        }
        else {
            navigationController!.popViewController(animated: true)
        }
    }
    
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        // saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        checkValidMealName()
        navigationItem.title = textField.text
    }
    
    func checkValidMealName() {
        // Disable the Save button if the text field is empty.
        //let text = nameTextField.text ?? ""
        //saveButton.isEnabled = !text.isEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Handle the text field’s user input through delegate callbacks.
        nameTextField.delegate = self
        if let student = student {
            navigationItem.title = student.name
            nameTextField.text   = student.name
            schoolNameTextField.text = student.school
            medicalInfoTextField.text = student.notes
            studentPhoto.image = student.photo
            //ratingControl.rating = student.rating
        }
        
        checkValidMealName()
        //studentPhoto = UIImageView(frame:CGRect(x:0, y:0, width:100, height: 70))
        //studentPhoto.contentMode = .scaleAspectFit
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

