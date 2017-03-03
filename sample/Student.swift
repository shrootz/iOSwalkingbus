//
//  Student.swift
//  sample
//
//  Created by Subie Madhavan on 11/3/16.
//  Copyright © 2016 seniordesign. All rights reserved.
//

import UIKit

class Student {
    // MARK: Properties
    var name: String
    var school: String
    var notes: String
    var photo: UIImage?
    var schedule_dictionary_coordinates: [String: [Double]]
    var schedule_dictionary_names: [String: String]
    var database_pointer: String
    var school_lat: Double?
    var school_long: Double?
    
    // MARK: Initialization
    
    init?(name: String, photo: UIImage?, school: String, notes: String, schedule_dictionary_coordinates: [String: [Double]], schedule_dictionary_names: [String: String], database_pointer: String, school_lat:Double, school_long:Double) {
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.school = school
        self.notes = notes
        self.schedule_dictionary_coordinates = schedule_dictionary_coordinates
        self.schedule_dictionary_names = schedule_dictionary_names
        self.database_pointer = database_pointer
        self.school_long = school_long
        self.school_lat = school_lat
        if name.isEmpty {
            return nil
        }
    }
    
    func setImage(photo: UIImage) {
        self.photo = photo
    }
    
    func setSchoolLat(lat: Double) {
        school_lat = lat
    }
    
    func setSchoolLong(long: Double) {
        school_long = long
    }
    
}
