//
//  StudentTableViewController.swift
//  sample
//
//  Created by Subie Madhavan on 11/3/16.
//  Copyright © 2016 seniordesign. All rights reserved.
//

import UIKit

class StudentTableViewController: UITableViewController {
    
    var students = [Student]()
    
    func loadSampleStudents() {
        let photo1 = UIImage(named: "DefaultImage")!
        let student1 = Student(name: "Bob", photo: photo1, school:"", notes:"")!
        
        let photo2 = UIImage(named: "DefaultImage")!
        let student2 = Student(name: "Sally", photo: photo2, school:"", notes:"")!
        
        let photo3 = UIImage(named: "DefaultImage")!
        let student3 = Student(name: "Tom", photo: photo3, school:"", notes:"")!
        
        students += [student1, student2, student3]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = editButtonItem

        loadSampleStudents()
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

}
