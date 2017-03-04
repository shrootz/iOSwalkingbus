//
//  MapViewController.swift
//  sample
//
//  Created by Subie Madhavan on 1/25/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

class MapViewController: UIViewController, GMSMapViewDelegate {
    
    var longitude:Double = -97.7431
    var latitude:Double = 30.2672
    var school_database_reference:String?
    var ref:FIRDatabaseReference?
    var student: Student?
    var time: String?
    
    var currentMarker : GMSMarker?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func loadView() {
        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.
        /*if (student?.school_lat != nil && student?.school_long != nil) {
            print("not nil")
            self.latitude = (student?.school_lat)!
            self.longitude = (student?.school_long)!
            let camera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 15.0)
            let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            self.view = mapView

        } else { */
            print("nil")
            let camera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 6.0)
            let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            mapView.delegate = self
            self.view = mapView
        //}
        ref = FIRDatabase.database().reference()
        
        ref?.child(school_database_reference!).child("lat").observeSingleEvent(of: .value, with: {(snap) in
            print("reading school coordinates")
            if snap.exists(){
                    print(snap)
                    //self.longitude = (snap.childSnapshot(forPath: "latitude").value as? Double)!
                    self.latitude = snap.value as! Double
                
                self.ref?.child(self.school_database_reference!).child("lng").observeSingleEvent(of: .value, with: {(snap2) in
                    print("reading school coordinates")
                    if snap2.exists(){
                        self.longitude = snap2.value as! Double
                        //self.latitude = (snap.childSnapshot(forPath: "longitude").value as? Double)!
                    }
                })
            }
            else{
                print("incorrect school")
            }
            
            self.ref?.child(self.school_database_reference!).child("routes").observeSingleEvent(of: .value, with: { (snap3) in
                for item in snap3.children.allObjects {
                    self.ref?.child("routes").child((item as AnyObject).key).child("location").observeSingleEvent(of: .value, with: {(snap4) in
                        if snap4.exists(){
                            let route_lat = snap4.childSnapshot(forPath: "lat").value as! Double
                            let route_long = snap4.childSnapshot(forPath: "lng").value as! Double
                            print(route_lat)
                            print(route_long)
                            let marker = GMSMarker()
                            marker.position = CLLocationCoordinate2D(latitude: route_lat, longitude: route_long)
                            marker.map = (self.view as! GMSMapView)
                            /*if (self.student?.schedule_dictionary_coordinates[self.time!]?[0] == route_lat && self.student?.schedule_dictionary_coordinates[self.time!]?[1] == route_long ) {
                                self.currentMarker = marker
                                marker.icon = GMSMarker.markerImage(with: .black)
                            } else {
                                marker.icon = GMSMarker.markerImage(with: .red)
                            } */
                            marker.userData = (item as AnyObject).key as String!
                        }
                    })
                }
            })
            
            
            DispatchQueue.main.async() {
                // update some UI
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
                CATransaction.begin()
                CATransaction.setValue(2.0, forKey: kCATransactionAnimationDuration)
                let newcamera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 15.0)
                (self.view as! GMSMapView).animate(to: newcamera)
                marker.map = (self.view as! GMSMapView)
                marker.icon = GMSMarker.markerImage(with: .green)
                marker.userData = "school_marker"
                CATransaction.commit()
            }
            
        })
    
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        
        if let destinationNavigationController = parent as? UINavigationController {
        let targetController = destinationNavigationController.topViewController
        if let editStudentTableViewController = targetController as? EditStudentTableViewController {
            editStudentTableViewController.student = self.student
        }
        } else {
            if let editStudentTableViewController = parent as? EditStudentTableViewController {
                print("hfedskughvksfhlxcv")
                editStudentTableViewController.student = self.student
            }
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
                if marker.userData as! String != "school_marker" {
                    if(currentMarker != nil) {
                        currentMarker?.icon = GMSMarker.markerImage(with: .red)
                    }
                    marker.icon = GMSMarker.markerImage(with: .black)
                    currentMarker = marker
                }
        return true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Saving updated parent...")
        if(currentMarker != nil){
        print(currentMarker?.userData as! String)
    
        self.ref?.child("/routes/").child(currentMarker?.userData as! String).child("students/").child(time!).child((student?.studentDatabaseId)!).setValue(student?.name)
        print("one fin")
        //self.ref?.child("students/").child((student?.database_pointer)!).child("/routes/").child(time!).setValue(currentMarker?.userData  as! String)
        print("fin all")
        }
    }
}

    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
