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

class MapViewController: UIViewController, GMSMapViewDelegate, UINavigationControllerDelegate {
    
    //MARK: - Variables
    var longitudeDefault:Double = -97.7431
    var latitudeDefault:Double = 30.2672
    var student: Student?
    var time: String?
    var currentMarker : GMSMarker?
    var markerRouteKeyMapping: [String:GMSMarker] = [:] //allows for loading name of route later
    

    
    
    //MARK: - Load
    override func loadView() {
        //initalizeMapUI
        let camera = GMSCameraPosition.camera(withLatitude: self.latitudeDefault, longitude: self.longitudeDefault, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.delegate = self
        self.view = mapView
        navigationController?.delegate = self
        loadMarkers()
        
    }
    
    func loadMarkers() {
        let schoolLatDatabaseReference = FIRDatabase.database().reference().child("schools").child((student?.schoolDatabaseId)!).child("lat")
        let schoolLongDatabaseReference = FIRDatabase.database().reference().child("schools").child((student?.schoolDatabaseId)!).child("lng")
        
        schoolLatDatabaseReference.observeSingleEvent(of: .value, with: {(latSnap) in
            if latSnap.exists(){
                self.latitudeDefault = latSnap.value as! Double
                schoolLongDatabaseReference.observeSingleEvent(of: .value, with: {(lngSnap) in
                    if lngSnap.exists(){
                        self.longitudeDefault = lngSnap.value as! Double
                    }
                })
            }
            else{
                print("Error getting school coordinates")
            }
            
            self.loadRouteMarkers()
        })

        
    }
    
    func loadMap(lat: Double, long:Double, zoom: Double) {
        
    }
    
    func loadRouteMarkers() {
        let databaseReference =  FIRDatabase.database().reference().child("schools").child((student?.schoolDatabaseId)!).child("routes")

        databaseReference.observeSingleEvent(of: .value, with: { (routesSnap) in
            if (routesSnap.exists()) {
                for route in routesSnap.children.allObjects {
                    let routeDatabaseReference = FIRDatabase.database().reference().child("routes").child((route as AnyObject).key).child("location")
                    routeDatabaseReference.observeSingleEvent(of: .value, with: {(routeSnap) in
                        if routeSnap.exists(){
                            let routeLat = routeSnap.childSnapshot(forPath: "lat").value as! Double
                            let routeLong = routeSnap.childSnapshot(forPath: "lng").value as! Double
                            let routeKey = (route as AnyObject).key as String
                            self.loadRouteName(routeKey: routeKey)
                            self.loadMarkerOnUi(lat: routeLat, long: routeLong, title: "", userData: routeKey)
                        }
                    })
                }
                //draw the school on the map
                 self.loadMap()
            } else {
                //draw school on map anyways
                self.loadMap()
            }
        })


    }
    func loadRouteName(routeKey:String){
        let nameDatabaseReference = FIRDatabase.database().reference().child("routes").child(routeKey).child("name")
        nameDatabaseReference.observeSingleEvent(of: .value, with: { (routeNameSnap) in
            if (routeNameSnap.exists()) {
                let routeName = routeNameSnap.value as! String
                self.markerRouteKeyMapping[routeKey]?.title = routeName
                
            }
        })
        
    }
    func loadMap() {
        DispatchQueue.main.async() {
            self.loadMarkerOnUi(lat: self.latitudeDefault, long: self.longitudeDefault, title: "school", userData: "")
            CATransaction.begin()
            CATransaction.setValue(2.0, forKey: kCATransactionAnimationDuration)
            let newcamera = GMSCameraPosition.camera(withLatitude: self.latitudeDefault, longitude: self.longitudeDefault, zoom: 15.0)
            (self.view as! GMSMapView).animate(to: newcamera)
            CATransaction.commit()
        }
    }
    
    func loadMarkerOnUi(lat: Double, long: Double, title:String, userData:String) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        marker.map = (self.view as! GMSMapView)
        marker.title = title
        marker.userData = userData
        markerRouteKeyMapping[userData] = marker
        
        if (title == "school") {
            marker.icon = GMSMarker.markerImage(with: .green)
        } else {
            let checkTimeInSchedule = student?.schedule[time!]
            if checkTimeInSchedule?[0] == userData {
                marker.icon = GMSMarker.markerImage(with: .red)
                self.currentMarker = marker
                
                
            } else {
                marker.icon = GMSMarker.markerImage(with: .black)
            }
        }
        
    }
    
    //MARK: - MapView delegate
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if marker.title != "school" {
            if(currentMarker != nil) {
                currentMarker?.icon = GMSMarker.markerImage(with: .black)
                if (currentMarker?.userData as! String == marker.userData as! String) { //deselect current marker by tapping on it
                    marker.icon = GMSMarker.markerImage(with: .black)
                    currentMarker = nil
                }
            } else {
                marker.icon = GMSMarker.markerImage(with: .red)
                currentMarker = marker
            }
        }
        return true
    }
    
    // MARK: - Navigation
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let controller = viewController as? EditStudentTableViewController {
            print("Sending updated student object back...")
            if (currentMarker == nil) { //route has been cleared
                student?.schedule[time!]?[1] = "" //name
                student?.schedule[time!]?[0] = "" //dbkey
            } else {
                student?.schedule[time!]?[1] = (currentMarker?.title!)! //name
                student?.schedule[time!]?[0] = currentMarker?.userData as! String //dbkey
            }
            print(self.student?.schedule)
            controller.student = self.student
        }
    }

}
