//
//  ChaperoneTableViewController.swift
//  sample
//
//  Created by Sneha Shrotriya on 2/8/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import Firebase
import UIKit
import CoreBluetooth
import CoreLocation

class ChaperoneTableViewController: UITableViewController, CLLocationManagerDelegate {
    //MARK: - Variables
    var appUser: User?
    var students = [Student]()
    var centralManager: CBCentralManager?
    var peripherals = Array<CBPeripheral>()
    var expectedTags = Array<String>()
    var currentStudentsWithChaperone = [String]()
    //var routeDate: Date = Date()
    var routeStatus: String = ""
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var groupActionButton: UIBarButtonItem!
    
    @IBAction func resetStudentStatusButton(_ sender: Any) {
        for student in students {
            student.status = "waiting"
            let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
            databaseReference.setValue(student.status)
            self.routeStatus = "waiting"
            FIRDatabase.database().reference().child("routes").child((self.appUser?.routes?[0])!).child("private").child("status").setValue(self.routeStatus)
            groupActionButton.isEnabled = true
            groupActionButton.title = "Leaving"
            //appUser?.bluetoothMapScans.removeAll()
            //appUser?.bluetoothMapStudent.removeAll()
            //appUser?.studentsWithChaperone.removeAll()
        }
        tableView.reloadData()
    }
    
    @IBAction func groupActionButton(_ sender: UIBarButtonItem) {
        if sender.title == "Leaving" {
            print(appUser?.studentsWithChaperone)
            self.findBluetoothWithStudents()
            let alertTitle = "You are picking up " + String((appUser?.studentsWithChaperone.count)!) + " students. " + String(students.count) + " students are registered for this bus."
            //1. Create the alert controller.
            let alert = UIAlertController(title: alertTitle, message: "Are you sure you want to leave?", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            //alert.addTextField { (textField) in
            //    textField.text = ""
            //}
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                self.updateStatusFromBlueTooth()
                for student in self.students {
                    if (student.status == "waiting") {
                        student.status = "left behind"
                    }
                    let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
                    databaseReference.setValue(student.status)
                }
                self.tableView.reloadData()
                sender.title = "Dropping Off"
                self.routeStatus = "picked up"
                FIRDatabase.database().reference().child("routes").child((self.appUser?.routes?[0])!).child("private").child("status").setValue(self.routeStatus)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
        } else if sender.title == "Dropping Off" {
            autoDropOff()
            /*
            self.routeStatus = "dropped off"
            FIRDatabase.database().reference().child("routes").child((self.appUser?.routes?[0])!).child("private").child("status").setValue(self.routeStatus)
            for student in students {
                if (student.status == "picked up") {
                    student.status = "dropped off"
                }
                let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
                databaseReference.setValue(student.status)
            }
            tableView.reloadData()
            sender.isEnabled = false
             */
        }
    }
    //MARK: - Load
    override func viewDidLoad() {
        super.viewDidLoad()
        loadRouteInfo()
        loadStudents()
        
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        //expectedTags.append("CB4C2E61-FEF3-47FF-8AEC-67A9B883016C")
        expectedTags.append("WalkingBus")
        
        //setup locationManager
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        // 1. status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
            // 2. authorization were denied
        else if CLLocationManager.authorizationStatus() == .denied {
            print("Location services were previously denied. Please enable location services for this app in Settings.")
        }
            // 3. we do have authorization
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
        
        // setup test data
        setupData()
    }
    
    func loadRouteInfo(){
        print("Loading the route info")
        var currentRoute = ""
        if (appUser?.routes) != nil && (appUser?.routes?.count)! > 0{ 
            currentRoute = appUser?.routes?[0] ?? ""
        }
        if !(currentRoute.isEmpty){
            FIRDatabase.database().reference().child("routes").child(currentRoute).child("public").observeSingleEvent(of: .value, with: { (routeDetailsSnap) in
                self.title = (routeDetailsSnap.childSnapshot(forPath: "name").value as? String)!
            })
            FIRDatabase.database().reference().child("routes").child(currentRoute).child("private").child("status").observeSingleEvent(of: .value, with: { (routeStatusDetailsSnap) in
                if(routeStatusDetailsSnap.exists()){
                    self.routeStatus = (routeStatusDetailsSnap.value as? String)!
                    if(self.routeStatus == "picked up"){
                        self.groupActionButton.title = "Dropping Off"
                    }
                    else if(self.routeStatus == "dropped off"){
                        self.groupActionButton.isEnabled = false
                    }
                    else if(self.routeStatus == "waiting"){
                        self.groupActionButton.title = "Leaving"
                        self.appUser?.bluetoothMapScans.removeAll()
                        self.appUser?.bluetoothMapStudent.removeAll()
                        self.appUser?.studentsWithChaperone.removeAll()
                    }
                }
            })
            
        } else {
            print("no routes")
            self.title = "No Route"
            self.navigationItem.leftBarButtonItems?[1].isEnabled = false //TODO: Remove this when you get rid of reset
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    func loadStudents(){
        print("Loading the students")
        var currentRoute = ""
        if (appUser?.routes) != nil && (appUser?.routes?.count)! > 0{
            currentRoute = appUser?.routes?[0] ?? ""
        }
        print("currentRoute is " + currentRoute)
        print("currentTime is " + (self.appUser?.currentTime)!)
        if !(currentRoute.isEmpty){
            FIRDatabase.database().reference().child("routes").child(currentRoute).child("private")
                .child("students").child((self.appUser?.currentTime)!).observeSingleEvent(of: .value, with: { (routeStudentDetailsSnap) in
                for student in routeStudentDetailsSnap.children.allObjects{
                    let studentKey = (student as AnyObject).key as String
                    if !studentKey.isEmpty {
                        self.loadSingleStudent(studentKey: studentKey)
                    }
                }
            }) { (error) in
                //code here not called either
                print("did not get any students")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadSingleStudent(studentKey: String){
        print("Loading single student with key " + studentKey)
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
            //TODO: don't forget to delete the child under the specific routes?
            let myStudent = Student(name: student_name!, photo: UIImage(named:"DefaultImage"), schoolName:school_name, info:student_notes, schedule:[:], studentDatabaseId:studentKey, schoolDatabaseId:student_school, bluetooth: student_bluetooth, status:student_status)!
            self.students += [myStudent]
            if(student_status == "picked up"){
                if !(self.appUser?.studentsWithChaperone.contains(student_bluetooth))!{
                    self.appUser?.studentsWithChaperone.append(student_bluetooth)
                    self.appUser?.bluetoothMapStudent[student_bluetooth] = myStudent
                    self.appUser?.bluetoothMapScans[student_bluetooth] = 0
                }
            }
            else if(student_status == "lost"){
                if !(self.appUser?.studentsWithChaperone.contains(student_bluetooth))!{
                    self.appUser?.studentsWithChaperone.append(student_bluetooth)
                    self.appUser?.bluetoothMapStudent[student_bluetooth] = myStudent
                    self.appUser?.bluetoothMapScans[student_bluetooth] = 10
                }
            }
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
    func setupData() {
        // 1. check if system can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            // 2. region data
            let title = "School"
            //let coordinate = CLLocationCoordinate2DMake(30.286395, -97.744514)
            let coordinate = CLLocationCoordinate2DMake(20.286395, -97.744514)
            let regionRadius = 100.0
            
            // 3. setup region
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                         longitude: coordinate.longitude), radius: regionRadius, identifier: title)
            
            region.notifyOnEntry=true
            region.notifyOnExit=true
            
            locationManager.startMonitoring(for: region)
            locationManager.requestState(for: region)

        }
        else {
            print("System can't track regions")
        }
    }
    
    //1. user enter region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("enter \(region.identifier)")
        autoDropOff()
    }
    
    // 2. user exit region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("exit \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion){
        if (state == CLRegionState.inside){
            print("I AM INSIDE")
            autoDropOff()
        } else if (state == CLRegionState.outside){
            print("I AM OUTSIDE")
        } else if (state == CLRegionState.unknown){
            print("UNKNOWN")
            return;
        }
    }
    
    func autoDropOff(){
        if(self.routeStatus == "picked up"){
            self.routeStatus = "dropped off"
            FIRDatabase.database().reference().child("routes").child((self.appUser?.routes?[0])!).child("private").child("status").setValue(self.routeStatus)
            for student in students {
                if (student.status == "picked up") {
                    student.status = "dropped off"
                }
                let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
                databaseReference.setValue(student.status)
            }
            tableView.reloadData()
            groupActionButton.isEnabled = false
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        self.appUser?.lastLat = locValue.latitude
        self.appUser?.lastLong = locValue.longitude
    }
    
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
                //cell.statusButton.setTitle("Pick Up", for: .normal)
                //cell.statusButton.setTitleColor(.green, for: .normal)
                cell.statusButton.isEnabled = false
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
    
    func updateStatusFromBlueTooth(){
        for bluetooth_found in (appUser?.studentsWithChaperone)!{
            if let myStudent = appUser?.bluetoothMapStudent[bluetooth_found]{
                myStudent.status = "picked up"
                let databaseReference = FIRDatabase.database().reference().child("students").child((myStudent.studentDatabaseId)).child("status")
                    databaseReference.setValue(myStudent.status)
            }
        }
        tableView.reloadData()
    }
    
    func findBluetoothWithStudents(){
        for (index,bluetooth_found) in (appUser?.studentsWithChaperone.enumerated())!{
            var bluetooth_is_found = false
            for currentStudent in students{
                let student_bluetooth = currentStudent.bluetooth
                if student_bluetooth == bluetooth_found {
                    appUser?.bluetoothMapStudent[bluetooth_found] = currentStudent
                    appUser?.bluetoothMapScans[bluetooth_found] = 0
                    bluetooth_is_found = true
                }
            }
            if(!bluetooth_is_found){
                appUser?.studentsWithChaperone.remove(at: index)
            }
        }
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

extension ChaperoneTableViewController: CBCentralManagerDelegate {
    func startScanning(){
        let scanPeriod = 5
        self.centralManager?.scanForPeripherals(withServices : nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        self.perform(#selector(stopScanning), with: self, afterDelay: Double(scanPeriod))
    }
    
    func stopScanning(){
        peripherals.removeAll()
        if(self.routeStatus == "picked up"){
            var set1:Set<String> = Set(appUser!.studentsWithChaperone)
            let set2:Set<String> = Set(currentStudentsWithChaperone)
            let set3 = set2.intersection(set1)
            set1.subtract(set2)
            for mac in set1 {
                if let value = appUser?.bluetoothMapScans[mac] {
                    appUser?.bluetoothMapScans[mac] = value + 1
                    if(appUser?.bluetoothMapScans[mac] == 3){
                        appUser?.bluetoothMapStudent[mac]?.status = "lost"
                        let databaseReference = FIRDatabase.database().reference().child("students").child((appUser?.bluetoothMapStudent[mac]?.studentDatabaseId)!)
                        databaseReference.child("status").setValue(appUser?.bluetoothMapStudent[mac]?.status)
                        databaseReference.child("location").child("lat").setValue(appUser?.lastLat)
                        databaseReference.child("location").child("lng").setValue(appUser?.lastLong)
                        
                        tableView.reloadData()
                    }
                }
            }
            for mac in set3 {
                if let value = appUser?.bluetoothMapScans[mac] {
                    if(value >= 3){
                        appUser?.bluetoothMapStudent[mac]?.status = "picked up"
                        let databaseReference = FIRDatabase.database().reference().child("students").child((appUser?.bluetoothMapStudent[mac]?.studentDatabaseId)!)
                        databaseReference.child("status").setValue(appUser?.bluetoothMapStudent[mac]?.status)
                        databaseReference.child("location").removeValue()
                        tableView.reloadData()
                    }
                    appUser?.bluetoothMapScans[mac] = 0
                }
            }
            currentStudentsWithChaperone.removeAll()
        }
        if (routeStatus != "dropped off"){
            startScanning()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            startScanning()
        }
        else {
            // do something like alert the user that ble is not on
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pName = peripheral.name{
            if(expectedTags.contains(pName) && !peripherals.contains(peripheral)){
                print("\nNew expected tag found! \(peripheral)")
                peripherals.append(peripheral)
                if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data{
                    assert(manufacturerData.count>=7)
                    
                    //0d00 - TI manufacturer ID - 2 byte
                    var manufacturerID = String(format: "%02X", (manufacturerData[0]))
                    manufacturerID += String(format: "%02X", (manufacturerData[1]))
                    print("Manufacturer ID: \(manufacturerID)")
                    
                    //6 byte MAC address
                    var MACAddress = String(format: "%02X", manufacturerData[2])
                    for i in 3...7  {
                        MACAddress += ":"
                        MACAddress += String(format: "%02X", manufacturerData[i])
                    }
                    print("MAC Address: \(MACAddress)")
                    if(self.routeStatus == "waiting"){
                        if !(appUser?.studentsWithChaperone.contains(MACAddress))!{
                            appUser?.studentsWithChaperone.append(MACAddress)
                        }
                    }
                    else if(self.routeStatus == "picked up"){
                        if !currentStudentsWithChaperone.contains(MACAddress){
                            currentStudentsWithChaperone.append(MACAddress)
                        }
                    }
                    //1 byte battery level
                    let batteryLevel = Int(manufacturerData[8])
                    print("Battery Level: \(batteryLevel)%")
                }
            }
        }
    }
}

