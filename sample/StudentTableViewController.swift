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
    
    var students = [Student]()
    var ref: FIRDatabaseReference?
    var parent_location: String?
    var parent_auth_id: String?
    
    
    func loadStudents() {
        var photo1 = UIImage(named: "DefaultImage")!
        print("Loading Students...")
        var coordinates: [String:[Double]] = [:]
        var names: [String:String] = [:]
        
        ref?.child(parent_location!).child("students").observeSingleEvent(of: .value, with: { (snapshot) in
            for item in snapshot.children {
                let val = (item as AnyObject).key as String
                print(val)
                self.ref?.child("/students/").child(val).observeSingleEvent(of: .value, with: { (snapshot2) in
                    print("GET")
                    print(snapshot2)
                    let student_name = snapshot2.childSnapshot(forPath: "name").value as? String
                    let student_notes = snapshot2.childSnapshot(forPath: "info").value as? String
                    let student_school = snapshot2.childSnapshot(forPath: "school").value as? String
                    if snapshot2.hasChild("photoUrl"){
                        let filePath = "\(val)/\("photoUrl")"
                        FIRStorage.storage().reference().child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                            print("storing the image")
                            if let imageUrl = UIImage(data: data!) {
                                photo1 = imageUrl  // you can use your imageUrl UIImage (note: imageUrl it is not an optional here)
                                for student in self.students {
                                    if student.database_pointer == val{
                                        student.setImage(photo: photo1)
                                        DispatchQueue.main.async{
                                            self.tableView.reloadData()
                                        }
                                    }
                                    
                                }
                            }
                        })
                    }
                    let student1 = Student(name: student_name!, photo: photo1, school:student_school!, notes:student_notes!, schedule_dictionary_coordinates:coordinates, schedule_dictionary_names:names, database_pointer:val, school_lat:0.0, school_long:0.0)!
                    self.students += [student1]
                    
                    for item2 in snapshot2.childSnapshot(forPath: "routes").children.allObjects{
                        self.ref?.child("/routes/").child((item2 as AnyObject).value as String).observeSingleEvent(of: .value, with: { (snapshot3) in
                            student1.schedule_dictionary_names[((item2 as AnyObject).key as String)] = (snapshot3.childSnapshot(forPath: "name").value as? String)!
                            student1.schedule_dictionary_coordinates[(item2 as AnyObject).key] = [(snapshot3.childSnapshot(forPath: "location/lat").value as? Double)!,(snapshot3.childSnapshot(forPath: "location/lng").value as? Double)!]
                            DispatchQueue.main.async{
                                self.tableView.reloadData()
                            }
                        })
                    }
                    
                    print("size of students\(self.students.count)")
                    DispatchQueue.main.async{
                        self.tableView.reloadData()
                    }
                })
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
        cell.schoolLabel.text = student.school
        cell.chaperoneLabel.text = student.notes
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
                studentDetailViewController.ref = self.ref
                studentDetailViewController.parent_auth_id = self.parent_auth_id
            }
        }
        else if segue.identifier == "AddItem" {
            print("Adding new student.")
            let studentDetailNavController = segue.destination as! UINavigationController
            let studentDetailViewController = studentDetailNavController.topViewController as! EditStudentTableViewController
            studentDetailViewController.ref = self.ref
            studentDetailViewController.parent_auth_id = self.parent_auth_id
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
