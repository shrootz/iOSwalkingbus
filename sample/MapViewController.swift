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

class MapViewController: UIViewController {
    
    var longitude:Double = -97.7431
    var latitude:Double = 30.2672
    var school_database_reference:String?
    var ref:FIRDatabaseReference?
    
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
        let camera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        self.view = mapView
        ref = FIRDatabase.database().reference()
        
        ref?.child(school_database_reference!).observeSingleEvent(of: .value, with: {(snap) in
            print("reading school coordinates")
            if snap.exists(){
                    self.longitude = (snap.childSnapshot(forPath: "latitude").value as? Double)!
                    self.latitude = (snap.childSnapshot(forPath: "longitude").value as? Double)!
            }else{
                print("incorrect school")
            }
            print("in edit \(self.longitude)")
            print("in edit \(self.latitude)")
            
            DispatchQueue.main.async() {
                // update some UI
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
                //marker.map = (self.view as! GMSMapView)
                CATransaction.begin()
                CATransaction.setValue(2.0, forKey: kCATransactionAnimationDuration)
                let newcamera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 15.0)
                (self.view as! GMSMapView).animate(to: newcamera)
                //let newCam = GMSCameraUpdate.setTarget(marker.position)
                //(self.view as! GMSMapView).moveCamera(newCam)
                marker.map = (self.view as! GMSMapView)
                marker.icon = GMSMarker.markerImage(with: .green)
                CATransaction.commit()

            }
            
            //let newcamera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 6.0)
            
            //(self.view as! GMSMapView).animate(to: newcamera)
            //let newCam = GMSCameraUpdate.setTarget(marker.position)
            //mapView.animate(with: newCam)
            //marker.icon = GMSMarker.markerImage(with: .black)
        })
        
        
        
        
        
        /*serialQueue.sync {
            print("in task2 \(self.longitude)")
            print("in task2 \(self.latitude)")
            let camera = GMSCameraPosition.camera(withLatitude: self.latitude, longitude: self.longitude, zoom: 6.0)
            let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            self.view = mapView
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            marker.map = mapView

        } */
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
