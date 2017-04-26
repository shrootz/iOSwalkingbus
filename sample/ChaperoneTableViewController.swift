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
    var centralManager: CBCentralManager?
    var peripherals = Array<CBPeripheral>()
    var expectedTags = Array<String>()
    var bluetoothToStudentMap = [String:Student]()
    var students = [Student]()
    var addressesFound = [String]()
    var routeStatus: String = ""
    let locationManager = CLLocationManager()
    
    var isScanning = true
    
    @IBOutlet weak var groupActionButton: UIBarButtonItem!
    
    @IBAction func resetStudentStatusButton(_ sender: Any) {
        self.routeStatus = "waiting"
        FIRDatabase.database().reference().child("routes").child((self.appUser?.routes?[0])!).child("private").child("status").setValue(self.routeStatus)
        groupActionButton.isEnabled = true
        groupActionButton.title = "Leaving"

        for student in students {
            student.status = "waiting"
            let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId).child("status")
            databaseReference.setValue(student.status)
        }
        
        tableView.reloadData()
        
        //startScanning()
    }
    
    @IBAction func groupActionButton(_ sender: UIBarButtonItem) {
        if sender.title == "Leaving" {
            var pickedUpCount = 0
            let registedCount = students.count
            for student in students {
                if (student.status == "picked up") {
                    pickedUpCount += 1
                }
            }
            let alertTitle = "You are picking up " + String(pickedUpCount) + " students. " + String(registedCount) + " student(s) are registered for this bus."
            //1. Create the alert controller.
            let alert = UIAlertController(title: alertTitle, message: "Are you sure you want to leave?", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            //alert.addTextField { (textField) in
            //    textField.text = ""
            //}
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
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
                //self.startScanning()
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
        } else if sender.title == "Dropping Off" {
            tryDropOff()
        }
    }
    
    func tryDropOff() {
        var lostCount = 0
        for student in students {
            if (student.status == "lost") {
                lostCount += 1
            }
        }
        
        if lostCount != 0 {
            let alertTitle = String(lostCount) + " student(s) are lost."
            //1. Create the alert controller.
            let alert = UIAlertController(title: alertTitle, message: "Are you sure you want to drop off?", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            //alert.addTextField { (textField) in
            //    textField.text = ""
            //}
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                self.dropOffUpdates()
                self.groupActionButton.isEnabled = false
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
            
        } else {
            dropOffUpdates()
            self.groupActionButton.isEnabled = false
        }
        
    }
    
    func dropOffUpdates() {
        print("Called drop off updates")
        //stopScanning()
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
        
        
    }
    //MARK: - Load
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        //expectedTags.append("CB4C2E61-FEF3-47FF-8AEC-67A9B883016C")
        expectedTags.append("WalkingBus")
        expectedTags.append("Walking Bus")
        
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

        
        loadRouteInfo()
        
        
    }
    
    func loadRouteInfo(){
        print("Loading the route info")
        var currentRoute = ""
        if (appUser?.routes) != nil && (appUser?.routes?.count)! > 0{ 
            currentRoute = appUser?.routes?[0] ?? "" //App supports only 1 route per user
        }
        if !(currentRoute.isEmpty){
            FIRDatabase.database().reference().child("routes").child(currentRoute).child("public").observeSingleEvent(of: .value, with: { (routeDetailsSnap) in
                self.title = (routeDetailsSnap.childSnapshot(forPath: "name").value as? String)!
                let school = (routeDetailsSnap.childSnapshot(forPath: "school").value as? String)!
                let lat = (routeDetailsSnap.childSnapshot(forPath: "location/lat").value as? Double)!
                let lng = (routeDetailsSnap.childSnapshot(forPath: "location/lng").value as? Double)!
                if (self.appUser?.currentTime.contains("am"))! {
                    self.setUpAutoDropOff(school: school)
                } else {
                    self.setUpAutoDropOff(lat:lat, lng:lng)
                }
            })
            FIRDatabase.database().reference().child("routes").child(currentRoute).child("private").child("status").observeSingleEvent(of: .value, with: { (routeStatusDetailsSnap) in
                if(routeStatusDetailsSnap.exists()){
                    self.routeStatus = (routeStatusDetailsSnap.value as? String)!
                    if(self.routeStatus == "picked up"){
                        self.groupActionButton.title = "Dropping Off"
                    }
                    else if(self.routeStatus == "dropped off"){
                        self.groupActionButton.title = "Dropping Off"
                        self.groupActionButton.isEnabled = false
                        self.displayToastMessage(displayText: "This bus has already happened.")
                        
                    }
                    else if(self.routeStatus == "waiting"){
                        self.groupActionButton.title = "Leaving"
                    }
                }
                self.loadStudents()
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
                if(self.routeStatus != "dropped off") {
                    //self.startScanning()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
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
            
            self.bluetoothToStudentMap[student_bluetooth] = myStudent
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
            if data != nil {
                if let photo = UIImage(data: data!) {
                    for student in self.students{
                        if student.studentDatabaseId == forStudent{
                            student.photo = photo
                            DispatchQueue.main.async{
                                self.tableView.reloadData()
                            }
                        }
                    
                    }
                }
            }
        })
    }
    func setUpAutoDropOff(lat: Double, lng:Double) {
        // 1. check if system can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            // 2. region data
            let title = "School"
            //let coordinate = CLLocationCoordinate2DMake(30.286395, -97.744514)
            let coordinate = CLLocationCoordinate2DMake(lat, lng)
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
    
    //MARK: - Functions
    func setUpAutoDropOff(school:String) {
        // 1. check if system can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
        
            // 2. region data
            let title = "School"
            //let coordinate = CLLocationCoordinate2DMake(30.286395, -97.744514)
            let schoolLatDatabaseReference = FIRDatabase.database().reference().child("schools").child(school).child("lat")
            let schoolLongDatabaseReference = FIRDatabase.database().reference().child("schools").child(school).child("lng")
            
            schoolLatDatabaseReference.observeSingleEvent(of: .value, with: {(latSnap) in
                if latSnap.exists(){
                    let lat = latSnap.value as! Double
                    schoolLongDatabaseReference.observeSingleEvent(of: .value, with: {(lngSnap) in
                        if lngSnap.exists(){
                            let long = lngSnap.value as! Double
                            let coordinate = CLLocationCoordinate2DMake(lat, long)
                            
                            let regionRadius = 100.0
                            
                            // 3. setup region
                            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                                         longitude: coordinate.longitude), radius: regionRadius, identifier: title)
                            
                            region.notifyOnEntry=true
                            region.notifyOnExit=true
                            
                            self.locationManager.startMonitoring(for: region)
                            self.locationManager.requestState(for: region)

                        }
                    })
                }
                else{
                    print("Error getting school coordinates")
                }
                
            })

            
        }
        else {
            print("System can't track regions")
        }
        
    }
    
    //1. user enter region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("enter \(region.identifier)")
        if (routeStatus == "picked up") {
            tryDropOff()
        }
    }
    
    // 2. user exit region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("exit \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion){
        if (state == CLRegionState.inside){
            print("I AM INSIDE")
            tryDropOff()
        } else if (state == CLRegionState.outside){
            print("I AM OUTSIDE")
        } else if (state == CLRegionState.unknown){
            print("UNKNOWN")
            return;
        }
    }
    
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
        return self.students.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ChaperoneStudentTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChaperoneStudentTableViewCell
        let student = students[indexPath.row]
        cell.studentName.text = student.name
        cell.studentPhoto.image = student.photo
        cell.studentInfo.text = student.info
        cell.foundButton.isHidden = true
        switch(student.status) {
            case "lost":
                cell.studentStatus.textColor = .red
                cell.foundButton.isHidden = false
                break
            case "left behind":
                cell.studentStatus.textColor = .gray
                break
            case "waiting":
                cell.studentStatus.textColor = .orange
                break
            default:
                cell.studentStatus.textColor = .green
                break
            
        }
        cell.studentStatus.text = student.status
        cell.foundButton.addTarget(self, action: #selector(self.updateStatus), for: .touchUpInside)
        cell.foundButton.tag = indexPath.row
        return cell
    }
    
    func updateStatus(sender:UIButton) {
        let buttonRow = sender.tag
        let currentStudent = students[buttonRow]
        sender.isHidden = true
        
        currentStudent.status = "picked up"
        
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
        if routeStatus == "picked up"{
            let alert = UIAlertController(title: "Bus in progress", message: "Are you sure you want to stop tracking?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let isPresentingInAddStudentMode = self.presentingViewController is UINavigationController
                
                if isPresentingInAddStudentMode {
                    self.dismiss(animated: true, completion: nil)
                }
                else {
                    self.navigationController!.popViewController(animated: true)
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in}))
            self.present(alert, animated: true, completion: nil)
        }
        else{
            let isPresentingInAddStudentMode = presentingViewController is UINavigationController
        
            if isPresentingInAddStudentMode {
                dismiss(animated: true, completion: nil)
            }
            else {
                navigationController!.popViewController(animated: true)
            }
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
        print ("Stopping scan and updating")
        //print(Thread.callStackSymbols)

        if(self.routeStatus == "waiting") {
            for address in addressesFound {
                if let student = bluetoothToStudentMap[address] { //ignore bluetooths that dont correspond to students
                    student.status = "picked up"
                    let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId)
                    databaseReference.child("status").setValue("picked up")
                }
            }
            
            var studentsBluetooths:Set<String> = Set(self.bluetoothToStudentMap.keys)
            let foundBluetooths:Set<String> = Set(self.addressesFound)
            
            studentsBluetooths.subtract(foundBluetooths)
            
            for lostBluetooth in studentsBluetooths {
                if let student = bluetoothToStudentMap[lostBluetooth] {
                    if student.status != "waiting" {
                        student.status = "waiting"
                        let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId)
                        databaseReference.child("status").setValue("waiting")
                    }
                }
            }
            
        } else if (self.routeStatus == "picked up") {
            for address in addressesFound {
                if let student = bluetoothToStudentMap[address] { //ignore bluetooths that dont correspond to students
                    if (student.status != "picked up") {
                        student.status = "picked up"
                        student.timeLastFound = Date()
                        let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId)
                        databaseReference.child("status").setValue("picked up")
                    }
                }
            }
            
            var studentsBluetooths:Set<String> = Set(self.bluetoothToStudentMap.keys)
            let foundBluetooths:Set<String> = Set(self.addressesFound)
            
            studentsBluetooths.subtract(foundBluetooths)
            
            for lostBluetooth in studentsBluetooths {
                if let student = bluetoothToStudentMap[lostBluetooth] {
                    let now = Date()
                    //let timeSinceLastFound:Double = now.timeIntervalSinceDate(student.timeLastFound);
                    
                    if (student.status != "lost" &&
                        (student.timeLastFound == nil || now.timeIntervalSince(student.timeLastFound!) > 30) &&
                        student.status != "left behind" ) {
                        student.status = "lost"
                        let databaseReference = FIRDatabase.database().reference().child("students").child(student.studentDatabaseId)
                        databaseReference.child("status").setValue("lost")
                        databaseReference.child("location").child("lat").setValue(appUser?.lastLat)
                        databaseReference.child("location").child("lng").setValue(appUser?.lastLong)
                    }
                }
            }

            
        }
        
        

        tableView.reloadData()
        addressesFound.removeAll()
        
        //disconnect from all found peripherals cause l o l
        /*for peripheral in self.peripherals {
            self.centralManager?.cancelPeripheralConnection(peripheral)
        } */
        
        
        peripherals.removeAll()
        
        
        if (routeStatus != "dropped off"){
            startScanning()
        }

        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("in did update state")
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
                //print("\nNew expected tag found! \(peripheral)")
                peripherals.append(peripheral)
                //self.centralManager?.connect(peripheral, options: nil)
                if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data{
                    assert(manufacturerData.count>=7)
                    
                    //0d00 - TI manufacturer ID - 2 byte
                    var manufacturerID = String(format: "%02X", (manufacturerData[0]))
                    manufacturerID += String(format: "%02X", (manufacturerData[1]))
                    //print("Manufacturer ID: \(manufacturerID)")
                    
                    //6 byte MAC address
                    var MACAddress = String(format: "%02X", manufacturerData[2])
                    for i in 3...7  {
                        MACAddress += ":"
                        MACAddress += String(format: "%02X", manufacturerData[i])
                    }
                    print("MAC Address: \(MACAddress)")
                    if (!addressesFound.contains(MACAddress)) {
                        addressesFound.append(MACAddress)
                    }//1 byte battery level
                    let batteryLevel = Int(manufacturerData[8])
                    print("Battery Level: \(batteryLevel)%")
                }
            }
        }
    }
}

