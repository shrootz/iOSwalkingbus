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

    
    func loadStudents() {
        print("HI BISH")
        let photo1 = UIImage(named: "DefaultImage")!
        let coordinates_empty : [String:[Double]] = [:]
        let names_empty : [String:String] = [:]
        
     //   var resultArray:[String] = []
     //   var students_array:[Student] = []
        
        ref?.child(parent_location!).child("children").observeSingleEvent(of: .value, with: { (snapshot) in
            for item in snapshot.children {
                let val = (item as AnyObject).value as String
                print(val)
                self.ref?.child("/children/").child(val).observeSingleEvent(of: .value, with: { (snapshot2) in
                    print("GET")
                    let student_name = snapshot2.value(forKey: "name") as! String
                    let student_notes = snapshot2.value(forKey: "bluetooth") as! String
                    let student1 = Student(name: student_name, photo: photo1, school:"", notes:student_notes, schedule_dictionary_coordinates:coordinates_empty, schedule_dictionary_names:names_empty)!
                    self.students += [student1]
                    print("size of students\(self.students.count)")
                    DispatchQueue.main.async{
                        self.tableView.reloadData()
                    }
                })
            }
        })
        
       // print("Results Array: \(resultArray)")
       // print("Results Array Count: \(resultArray.count)")
        
        /*ref?.child(parent_location!).child("children").observeSingleEvent(of: .value, with: { snapshot in
                //let val = snapshot.children.allObjects
                //print(snapshot.children.allObjects.value as String)
                for item in snapshot.children.allObjects{
                    let current_key = (item as AnyObject).key as String
                    let val = (item as AnyObject).value as String
                    print(val)

                } */
                //print("Results Array: \(resultArray)")
                //print("Results Array Count: \(resultArray.count)")
            
          //  })
        
    //    ref?.child(parent_location!).child("children").observe(.value, with: { snapshot in
      //      print(snapshot.value)
      //  })
    }
    
    func loadSampleStudents() {
        let photo1 = UIImage(named: "DefaultImage")!
        let coordinates : [String:[Double]] = [
            "monday_am" : [19.8968, -155.5825],
            "tuesday_am" : [30.2672, -97.7431],
            "wednesday_am" :[-41.8101, -68.9063],
            "thursday_am" :[-33.8688, 151.2093],
            "friday_am" : [20.5937, 78.9629]
            
        ]
        
        let names : [String:String] = [
            "monday_am" : "Hawaii",
            "tuesday_am" : "Austin",
            "wednesday_am" : "Patagonia",
            "thursday_am" : "Australia",
            "friday_am" : "India"
        ]
        let student1 = Student(name: "Bob", photo: photo1, school:"", notes:"", schedule_dictionary_coordinates:coordinates, schedule_dictionary_names: names)!
        
        let coordinates_empty : [String:[Double]] = [:]
        
        let names_empty : [String:String] = [:]

        let photo2 = UIImage(named: "DefaultImage")!
        let student2 = Student(name: "Sally", photo: photo2, school:"", notes:"", schedule_dictionary_coordinates:coordinates_empty, schedule_dictionary_names:names_empty)!
        
        let photo3 = UIImage(named: "DefaultImage")!
        let student3 = Student(name: "Tom", photo: photo3, school:"", notes:"", schedule_dictionary_coordinates:coordinates_empty, schedule_dictionary_names:names_empty)!
        
        students += [student1, student2, student3]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       let beeb = self.ref?.child("/children/").childByAutoId()
        beeb?.setValue(["name": "bob", "bluetooth":"11:11:11:11:11:11", "status":"lost", "parent":"seFA6JsWxJhJsYSCeVtoGgZmwNz2"])
        let parents_children = parent_location! + "/children"
        self.ref?.child(parents_children).childByAutoId().setValue((beeb?.key)!)
    
        
        loadSampleStudents()
        loadStudents()
        
        


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
            }
        }
        else if segue.identifier == "AddItem" {
            print("Adding new student.")
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
