//
//  StudentTableViewController.swift
//  sample
//
//  Created by Subie Madhavan on 11/3/16.
//  Copyright © 2016 seniordesign. All rights reserved.
//

import UIKit
import Firebase

class StudentTableViewController: UITableViewController {
    
    //MARK: - Variables
    var students = [Student]()
    var parentAuthId: String?
    var appUser: User?
    
    //MARK: - Load
    func loadStudents() {
        print("Getting details for students")
        for studentKey in (appUser?.students)! {
            FIRDatabase.database().reference().child("/students/").child(studentKey).observeSingleEvent(of: .value, with: { (studentDetailsSnap) in
                let student_name = studentDetailsSnap.childSnapshot(forPath: "name").value as? String
                let student_notes = studentDetailsSnap.childSnapshot(forPath: "info").value as? String ?? ""
                let student_school = studentDetailsSnap.childSnapshot(forPath: "school").value as? String ?? ""
                var school_name = ""
                if self.appUser?.schoolsParent != nil {
                    for (key, val) in (self.appUser?.schoolsParent)!{
                        if(val == student_school) {
                            school_name = key
                        }
                    }
                }
                
                //set up schedule dictionary for student
                var schedule = self.initSchedule()
                let routes = (studentDetailsSnap.childSnapshot(forPath: "routes").value as? [String:String])
                if routes != nil {
                    for route in (studentDetailsSnap.childSnapshot(forPath: "routes").value as? [String:String])! {
                        schedule[route.key] = [String](repeating: "", count:2)
                        schedule[route.key]?[0] = route.value
                    }
                }
                
                //create local student object
                let myStudent = Student(name: student_name!, photo: UIImage(named:"DefaultImage"), schoolName:school_name, info:student_notes, schedule:schedule, studentDatabaseId:studentKey, schoolDatabaseId:student_school)!
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
    
    func loadStudentPhoto(withLocation: String, forStudent:String) {
        print("Getting student photo from " + withLocation)
        FIRStorage.storage().reference().child(withLocation).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
            print("storing the image")
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadStudents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions 
    
    //FIXME: maybe? I think I work now
    func deleteStudentFromDatabase(student: Student) {
        let databaseReference = FIRDatabase.database().reference()
        //delete from routes
        for (time, route) in student.schedule {
            if route[0] != "" {
                databaseReference.child(route[0]).child("students").child(time).child(student.studentDatabaseId).removeValue()
            }
        }
        //delete from school
        databaseReference.child("schools").child(student.schoolDatabaseId).child("students").child(student.studentDatabaseId).removeValue()
        
        //delete from students node
        databaseReference.child("students").child(student.studentDatabaseId).removeValue()
        
        
        //delete from parents 
        databaseReference.child("users").child((appUser?.userAuthId)!).child("students").child(student.studentDatabaseId).removeValue()

    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "StudentTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! StudentTableViewCell
        let student = students[indexPath.row]
        cell.nameLabel.text = student.name
        cell.photoImageView.image = student.photo
        cell.schoolLabel.text = student.schoolName
        cell.chaperoneLabel.text = student.info
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let student = students[indexPath.row]
            students.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            //remove student from database
            print("Removing student " + student.name + " from database")
            deleteStudentFromDatabase(student: student)
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            print("Clicked on edit existing student")
            let studentDetailViewController = segue.destination as! EditStudentTableViewController
            
            // Get the cell that generated this segue.
            if let selectedStudentCell = sender as? StudentTableViewCell {
                let indexPath = tableView.indexPath(for: selectedStudentCell)!
                let selectedStudent = students[indexPath.row]
                studentDetailViewController.student = selectedStudent
                studentDetailViewController.appUser = self.appUser
                studentDetailViewController.oldSchool = selectedStudent.schoolDatabaseId
                studentDetailViewController.oldRoutes = selectedStudent.schedule
            }
        }
        else if segue.identifier == "AddItem" {
            print("Clicked on adding new student")
            let studentDetailNavController = segue.destination as! UINavigationController
            let studentDetailViewController = studentDetailNavController.topViewController as! EditStudentTableViewController
            studentDetailViewController.appUser = self.appUser
        }
    }
    
    @IBAction func unwindToStudentList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditStudentTableViewController, let student = sourceViewController.student {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                print("Updated an existing student.")
                students[selectedIndexPath.row] = student
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                print("Added a new student")
                let newIndexPath = IndexPath(row: students.count, section: 0)
                students.append(student)
                self.appUser = sourceViewController.appUser
                tableView.insertRows(at: [newIndexPath], with: .bottom)
            }
        }
    }
    
    @IBAction func unwindToStudentListBack(sender: UIStoryboardSegue) {
        //do nothing b/c you don't want to update any exsisting data
        print("Back button pressed from edit student page")
    }

    
}
