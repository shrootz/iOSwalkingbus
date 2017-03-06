//
//  ChaperoneTableViewController.swift
//  sample
//
//  Created by Sneha Shrotriya on 2/8/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import Firebase
import UIKit

class ChaperoneTableViewController: UITableViewController {
    //MARK: - Variables
    var appUser: User?
    var students = [Student]()
    
    
    @IBAction func resetStudentStatusButton(_ sender: Any) {
        for student in students {
            student.status = "waiting"
            let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
            databaseReference.setValue(student.status)
        }
        tableView.reloadData()
    }
    
    @IBAction func groupActionButton(_ sender: UIBarButtonItem) {
        if sender.title == "Leaving" {
            for student in students {
                if (student.status == "waiting") {
                    student.status = "left behind"
                }
                let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
                databaseReference.setValue(student.status)
            }
            tableView.reloadData()
            sender.title = "Dropping Off"
        } else if sender.title == "Dropping Off" {
            for student in students {
                if (student.status == "picked up") {
                    student.status = "dropped off"
                }
                let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
                databaseReference.setValue(student.status)
            }
            tableView.reloadData()
            sender.title = "Leaving"
        }
    }
    //MARK: - Load
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStudents()
    }
    
    func loadStudents(){
        print("Loading the students")
        if !(appUser?.routes.isEmpty)!{
            //TODO: find the actual time for the bus
            FIRDatabase.database().reference().child("routes").child((appUser?.routes)!).child("students").child("mon_am").observeSingleEvent(of: .value, with: { (routeStudentDetailsSnap) in
                for student in routeStudentDetailsSnap.children.allObjects{
                    let studentKey = (student as AnyObject).key as String
                    if !studentKey.isEmpty {
                        self.loadSingleStudent(studentKey: studentKey)
                    }
                }
            })
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadSingleStudent(studentKey: String){
        FIRDatabase.database().reference().child("students").child(studentKey).observeSingleEvent(of: .value, with: { (studentDetailsSnap) in
            let student_name = studentDetailsSnap.childSnapshot(forPath: "name").value as? String
            let student_notes = studentDetailsSnap.childSnapshot(forPath: "info").value as? String ?? ""
            let student_school = studentDetailsSnap.childSnapshot(forPath: "school").value as? String ?? ""
            let student_bluetooth = studentDetailsSnap.childSnapshot(forPath: "bluetooth").value as? String ?? ""
            let student_status = studentDetailsSnap.childSnapshot(forPath: "status").value as? String ?? ""
            var school_name = ""
            if self.appUser?.schoolsParent != nil {
                for (key, val) in (self.appUser?.schoolsParent)!{
                    if(val == student_school) {
                        school_name = key
                    }
                }
            }
            
            //create local student object
            let myStudent = Student(name: student_name!, photo: UIImage(named:"DefaultImage"), schoolName:school_name, info:student_notes, schedule:[:], studentDatabaseId:studentKey, schoolDatabaseId:student_school, bluetooth: student_bluetooth, status:student_status)!
            self.students += [myStudent]
            if studentDetailsSnap.hasChild("photoUrl"){
                let photoLocation = "\(studentKey)/\("photoUrl")"
                self.loadStudentPhoto(withLocation: photoLocation, forStudent:studentKey)
            }
            
            DispatchQueue.main.async{
                self.tableView.reloadData()
            }
        })
    }
    
    func loadStudentPhoto(withLocation: String, forStudent:String) {
        print("Getting student photo from " + withLocation)
        FIRStorage.storage().reference().child(withLocation).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
            if let photo = UIImage(data: data!) {
                for student in self.students {
                    if student.studentDatabaseId == forStudent{
                        student.photo = photo
                        DispatchQueue.main.async{
                            self.tableView.reloadData()
                        }
                    }
                    
                }
            }
        })
    }
    //MARK: - Functions
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return students.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ChaperoneStudentTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChaperoneStudentTableViewCell
        let student = students[indexPath.row]
        cell.studentName.text = student.name
        cell.studentPhoto.image = student.photo
        cell.studentInfo.text = student.info
        cell.studentStatus.text = student.status
        switch(student.status) {
            case "waiting":
                cell.statusButton.setTitle("Pick Up", for: .normal)
                cell.statusButton.setTitleColor(.green, for: .normal)
                break
            case "lost":
                cell.statusButton.setTitle("Found?", for: .normal)
                cell.statusButton.setTitleColor(.magenta, for: .normal)
                break
            case "picked up":
                cell.statusButton.setTitle("Lost?", for: .normal)
                cell.statusButton.setTitleColor(.red, for: .normal)
                break
            case "left behind":
                cell.statusButton.isEnabled = false
                cell.statusButton.setTitleColor(.gray, for: .normal)
                break
            case "dropped off":
                cell.statusButton.setTitle("Pick Up", for: .normal)
                cell.statusButton.setTitleColor(.green, for: .normal)
                break
            default:
                break
        }
        cell.statusButton.addTarget(self, action: #selector(self.updateStatus), for: .touchUpInside)
        cell.statusButton.tag = indexPath.row
        return cell
    }
    
    func updateStatus(sender:UIButton) {
        let buttonRow = sender.tag
        let currentStudent = students[buttonRow]
        let currentButtonText = sender.titleLabel?.text ?? ""
        switch (currentButtonText) {
        case "Pick Up":
            sender.setTitle("Lost?", for: .normal)
            sender.setTitleColor(.red, for: .normal)
            currentStudent.status = "picked up"
            break
        case "Lost?":
            sender.setTitle("Found?", for: .normal)
            sender.setTitleColor(.magenta, for: .normal)
            currentStudent.status = "lost"
            break
        case "Found?":
            sender.setTitle("Lost?", for: .normal)
            sender.setTitleColor(.red, for: .normal)
            currentStudent.status = "picked up"
            break
        default:
            break
        }
        let indexPath = IndexPath(row: buttonRow, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .none)
        let databaseReference = FIRDatabase.database().reference().child("students").child(currentStudent.studentDatabaseId).child("status")
        databaseReference.setValue(currentStudent.status)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    
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
    
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return false
    }
    
    
    // MARK: - Navigation
    @IBAction func goHome(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentingInAddStudentMode = presentingViewController is UINavigationController
        
        if isPresentingInAddStudentMode {
            dismiss(animated: true, completion: nil)
        }
        else {
            navigationController!.popViewController(animated: true)
        }
        
    }
    
}
