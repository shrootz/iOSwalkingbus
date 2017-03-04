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
                let student_notes = studentDetailsSnap.childSnapshot(forPath: "info").value as? String
                let student_school = studentDetailsSnap.childSnapshot(forPath: "school").value as? String
                let school_name = self.appUser?.schoolsParent?[student_school!]
                
                //set up schedule dictionary for student
                var schedule: [String: [String]] = [:]
                for route in (studentDetailsSnap.childSnapshot(forPath: "routes").value as? [String:String])! {
                    schedule[route.key] = [String](repeating: "", count:2)
                    schedule[route.key]?[0] = route.value
                }
                
                //create local student object
                print(student_name!)
                print(student_notes!)
                print(schedule)
                print(studentKey)
                print(student_school!)
                print(self.appUser?.schoolsParent!)
                print(school_name!)

                let myStudent = Student(name: student_name!, photo: UIImage(named:"DefaultImage"), schoolName:school_name!, info:student_notes!, schedule:schedule, studentDatabaseId:studentKey, schoolDatabaseId:student_school!)!
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
    
    
    
    @IBAction func unwindToStudentList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditStudentTableViewController, let student = sourceViewController.student {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing meal.
                print("Update an existing meal.")
                students[selectedIndexPath.row] = student
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add a new meal.
                let newIndexPath = IndexPath(row: students.count, section: 0)
                students.append(student)
                tableView.insertRows(at: [newIndexPath], with: .bottom)
            }
        }
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
            students.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
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
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let studentDetailViewController = segue.destination as! EditStudentTableViewController
            
            // Get the cell that generated this segue.
            if let selectedStudentCell = sender as? StudentTableViewCell {
                let indexPath = tableView.indexPath(for: selectedStudentCell)!
                let selectedStudent = students[indexPath.row]
                studentDetailViewController.student = selectedStudent
                studentDetailViewController.parent_auth_id = self.parentAuthId
            }
        }
        else if segue.identifier == "AddItem" {
            print("Adding new student.")
            let studentDetailNavController = segue.destination as! UINavigationController
            let studentDetailViewController = studentDetailNavController.topViewController as! EditStudentTableViewController
            studentDetailViewController.parent_auth_id = self.parentAuthId
        }
    }
    
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
