//
//  EditStudentTableViewController.swift
//  sample
//
//  Created by Subie Madhavan on 2/5/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import CoreBluetooth
import UIKit
import os.log
import Firebase

class EditStudentTableViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource{

    //MARK: - Outlets
    @IBOutlet weak var student_image: UIImageView!
    @IBOutlet weak var full_name: UITextField!
    @IBOutlet weak var student_notes: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var bluetoothButton: UIButton!
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
    @IBOutlet weak var schoolTextView: UITextField!
    
    //MARK: - Variables
    var student: Student?
    var appUser: User?
    var schoolNamesForUI:[String] = []
    var oldSchool = ""
    var oldRoutes: [String:[String]] = [:]
    var centralManager: CBCentralManager?
    var peripherals = Array<CBPeripheral>()
    var expectedTags = Array<String>()
    var MACAddress: String = ""
    
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

    //MARK: - Load
    override func viewDidLoad() {
        super.viewDidLoad()
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        //expectedTags.append("CB4C2E61-FEF3-47FF-8AEC-67A9B883016C")
        expectedTags.append("WalkingBus")
        loadUI()
        loadStudentSchedule()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.reloadRoutes()
    }
    
    func loadStudentSchedule(){
        if let schedule = student?.schedule {
            for time in (schedule.keys) {
                let routeId = student?.schedule[time]?[0]
                if (routeId != "") {
                    let databaseReference = FIRDatabase.database().reference().child("routes").child(routeId!).child("name")
                    databaseReference.observeSingleEvent(of: .value, with: {(routeName) in
                        if (routeName.exists()) {
                            self.student?.schedule[time]?[1] = routeName.value as! String
                        }
                        self.reloadRoutes()
                        
                    })
                    
                }
                
            }
        }
    }
    
    func loadUI() {
        full_name.delegate = self
        //fill picker
        schoolNamesForUI.append("")
        if let schoolsMapping = appUser?.schoolsParent {
            for (schoolName, _) in schoolsMapping {
                schoolNamesForUI.append(schoolName)
            }
        }
        let schoolPicker = UIPickerView()
        schoolPicker.delegate = self
        schoolPicker.dataSource = self
        schoolTextView.inputView = schoolPicker
        bluetoothButton.setTitle("Scan for Device", for: .normal)
        if let student = self.student {
            navigationItem.title = student.name
            full_name.text   = student.name
            student_notes.text = student.info
            student_image.image = student.photo
            schoolTextView.text = student.schoolName
            MACAddress = student.bluetooth
            if(MACAddress != ""){
                bluetoothButton.setTitle("Forget my Device", for: .normal)
            }
            //set picker to correct school
            let row = schoolNamesForUI.index(of: student.schoolName)
            schoolPicker.selectRow(row!, inComponent: 0, animated: false)
            reloadRoutes()
        }
    }
    
    func reloadRoutes() {
        print("Reloading routes")
        if let student = self.student {
            if let routeInfo = student.schedule["mon_am"]{
                if (routeInfo[1] == "") {
                    monday_am.setTitle("...", for: .normal)
                } else {
                    monday_am.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["mon_pm"]{
                if (routeInfo[1] == "") {
                    monday_pm.setTitle("...", for: .normal)
                } else {
                    monday_pm.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["tues_am"]{
                if (routeInfo[1] == "") {
                    tuesday_am.setTitle("...", for: .normal)
                } else {
                    tuesday_am.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["tues_pm"]{
                if (routeInfo[1] == "") {
                    tuesday_pm.setTitle("...", for: .normal)
                } else {
                    tuesday_pm.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["wed_am"]{
                if (routeInfo[1] == "") {
                    wednesday_am.setTitle("...", for: .normal)
                } else {
                    wednesday_am.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["wed_pm"]{
                if (routeInfo[1] == "") {
                    wednesday_pm.setTitle("...", for: .normal)
                } else {
                    wednesday_pm.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["thurs_am"]{
                if (routeInfo[1] == "") {
                    thursday_am.setTitle("...", for: .normal)
                } else {
                    thursday_am.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["thurs_pm"]{
                if (routeInfo[1] == "") {
                    thursday_pm.setTitle("...", for: .normal)
                } else {
                    thursday_pm.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["fri_am"]{
                if (routeInfo[1] == "") {
                    friday_am.setTitle("...", for: .normal)
                } else {
                    friday_am.setTitle(routeInfo[1], for: .normal)
                }
            }
            
            if let routeInfo = student.schedule["fri_pm"]{
                if (routeInfo[1] == "") {
                    friday_pm.setTitle("...", for: .normal)
                } else {
                    friday_pm.setTitle(routeInfo[1], for: .normal)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - PickerView Delegate
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return schoolNamesForUI.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return schoolNamesForUI[row]
    }
    
    // Catpure the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        schoolTextView.text = schoolNamesForUI[row]
    }
    
    // MARK: - Functions
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
    
    @IBAction func lookForBluetooth(_ sender: Any) {
        if(bluetoothButton.titleLabel!.text == "Forget my Device"){
            MACAddress = ""
            bluetoothButton.setTitle("Scan for New Device", for: .normal)
        }
        else{
            self.displayToastMessage(displayText: "Scanning for a student device")
            self.startScanning()
        }
    }
    
    func saveStudentToDatabase(){
        let parentArray: [String: String] =  [(self.appUser?.userAuthId)! : (self.appUser?.userAuthId)!]
        let studentInFirebase = FIRDatabase.database().reference().child("students").child((student?.studentDatabaseId)!)
        
        studentInFirebase.setValue([
            "name": student?.name,
            "school": student?.schoolDatabaseId,
            "info": student?.info,
            "bluetooth":student?.bluetooth,
            "status":"waiting",
            "parents":parentArray
            ])
        
        //adds my image to the firebase storage
        var data = Data()
        data = UIImageJPEGRepresentation((student?.photo!)!, 0)!
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpg"
        FIRStorage.storage().reference().child((student?.studentDatabaseId)!).child("photoUrl").put(data, metadata: metaData){(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }else{
                //store downloadURL
                let downloadURL = metaData!.downloadURL()!.absoluteString
                //store downloadURL at database
                studentInFirebase.updateChildValues(["photoUrl": downloadURL])
            }
        }
 
        //delete student from old school
        if !oldSchool.isEmpty {
            FIRDatabase.database().reference().child("schools").child(oldSchool).child("students").child((student?.studentDatabaseId)!).removeValue()
        }
        
        //add student to new school
            FIRDatabase.database().reference().child("schools").child((student?.schoolDatabaseId)!).child("students").child((student?.studentDatabaseId)!).setValue(student?.name)
        
        //delete from old routes
        for (time, routeInfo) in oldRoutes {
            if routeInfo[0] != ""{
                FIRDatabase.database().reference().child("routes").child(routeInfo[0]).child("students").child(time).child((student?.studentDatabaseId)!).removeValue()
                
                FIRDatabase.database().reference().child("students").child((student?.studentDatabaseId)!).child("routes").child(time).removeValue()
            }
        }
        
        //add to new routes
        for (time, routeInfo) in (student?.schedule)! {
            if routeInfo[0] != ""{
                
                FIRDatabase.database().reference().child("routes").child(routeInfo[0]).child("students").child(time).child((student?.studentDatabaseId)!).setValue("1")
                FIRDatabase.database().reference().child("students").child((student?.studentDatabaseId)!).child("routes").child(time).setValue(routeInfo[0])
                
            }
        }
        
    }
    
    func updateStudentObject() -> Bool{
        print("Updating the student in the database")
        let name = full_name.text ?? ""
        let school = schoolTextView.text ?? ""
        let notes = student_notes.text ?? ""
        let photo = student_image.image
        let bluetooth = MACAddress
        print("bluetooth found " + MACAddress)
        if (name == "" || school == "") {
            displayToastMessage(displayText: "Student must have name and school")
            return false
        }
        var studentSchedule = self.initSchedule()
        var studentDatabaseId = ""
        if (self.student != nil) {
            studentSchedule = (self.student?.schedule)!
            studentDatabaseId = (self.student?.studentDatabaseId)!
        }
        let schoolDatabaseId = appUser?.schoolsParent?[school]
        if let updatedStudent = Student(name: name, photo: photo, schoolName: school, info: notes, schedule: studentSchedule, studentDatabaseId: studentDatabaseId, schoolDatabaseId: schoolDatabaseId!, bluetooth: bluetooth) {
            self.student = updatedStudent
            return true;
        }
        
        return false;

    }
    
    func initSchedule() -> [String: [String]]{
        var schedule: [String: [String]] = [:]
        schedule["mon_am"] = [String](repeating: "", count:2)
        schedule["mon_pm"] = [String](repeating: "", count:2)
        schedule["tues_am"] = [String](repeating: "", count:2)
        schedule["tues_pm"] = [String](repeating: "", count:2)
        schedule["wed_am"] = [String](repeating: "", count:2)
        schedule["wed_pm"] = [String](repeating: "", count:2)
        schedule["thurs_am"] = [String](repeating: "", count:2)
        schedule["thurs_pm"] = [String](repeating: "", count:2)
        schedule["fri_am"] = [String](repeating: "", count:2)
        schedule["fri_pm"] = [String](repeating: "", count:2)
        return schedule
    }
    
    func updateParentObject() {
        //update parent object locally and in db
        print("The parent was updated in the database")
        appUser?.students?.append((student?.studentDatabaseId)!)
        FIRDatabase.database().reference().child("users").child((self.appUser?.userAuthId)!).child("students").child((student?.studentDatabaseId)!).setValue(student?.name)
        
    }
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        if let ident = identifier {
            print("verifies school and name of child exists")
            if ident == "m_am" || ident == "m_pm" || ident == "t_am" || ident == "t_pm" || ident == "w_am"
                || ident == "w_pm" || ident == "th_am" || ident == "th_pm" || ident == "f_am" || ident == "f_pm"{
                if (schoolTextView.text?.isEmpty)! {
                    displayToastMessage(displayText: "Select school to pick routes")
                    return false
                }
            } else if (ident == "back") {
                return true
            }
        }
        return updateStudentObject()
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if sender as AnyObject? === saveButton {
            if(student?.studentDatabaseId == ""){
                print("Saving a new child")
                let newChild = FIRDatabase.database().reference().child("students").childByAutoId()
                self.student?.studentDatabaseId = newChild.key as String!
                self.saveStudentToDatabase()
                self.updateParentObject()
            }
            else{
                print("Saving an old child")
                self.saveStudentToDatabase()
            }
        }
            
        else if sender as AnyObject? === monday_am {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "mon_am"
        }
        else if sender as AnyObject? === monday_pm {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "mon_pm"
        }
        else if sender as AnyObject? === tuesday_am {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "tues_am"
        }
        else if sender as AnyObject? === tuesday_pm {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "tues_pm"
        }
        else if sender as AnyObject? === wednesday_am {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "wed_am"
        }
        else if sender as AnyObject? === wednesday_pm {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "wed_pm"
        }
        else if sender as AnyObject? === thursday_am {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "thurs_am"
        }
        else if sender as AnyObject? === thursday_pm {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "thurs_pm"
        }
        else if sender as AnyObject? === friday_am {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "fri_am"
        }
        else if sender as AnyObject? === friday_pm {
            let mapViewController = segue.destination as! MapViewController
            mapViewController.student = self.student
            mapViewController.time = "fri_pm"
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
        textField.resignFirstResponder()
    }

}


extension EditStudentTableViewController: CBCentralManagerDelegate {
    func startScanning(){
        let scanPeriod = 10
        //displayToastMessage(displayText: "Device not found")
        self.centralManager?.scanForPeripherals(withServices : nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        self.perform(#selector(stopScanning), with: self, afterDelay: Double(scanPeriod))
    }
    
    func stopScanning(){
        if(peripherals.count == 0){
            displayToastMessage(displayText: "No device found")
        }
        else if (peripherals.count == 1){
            displayToastMessage(displayText: "Device found")
            bluetoothButton.setTitle("Forget my Device", for: .normal)
        }
        else{
            displayToastMessage(displayText: "Too many student devices found")
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state != .poweredOn){
            displayToastMessage(displayText: "Phone BLE is not turned on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pName = peripheral.name{
            if(expectedTags.contains(pName) && !peripherals.contains(peripheral)){
                print("\nNew expected tag found! \(peripheral)")
                peripherals.append(peripheral)
                if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data{
                    assert(manufacturerData.count>=7)
                    //6 byte MAC address
                    MACAddress = String(format: "%02X", manufacturerData[2])
                    for i in 3...7  {
                        MACAddress += ":"
                        MACAddress += String(format: "%02X", manufacturerData[i])
                    }
                }
            }
        }
    }
}

