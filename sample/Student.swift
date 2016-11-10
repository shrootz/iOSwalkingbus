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
    var medical: String
    var photo: UIImage?

    // MARK: Initialization
//    init?(name: String, photo: UIImage?) {
//        // Initialize stored properties.
//        self.name = name
//        self.photo = photo
//        self.school = ""
//        self.medical = ""
//        if name.isEmpty {
//            return nil
//        }
//    }
    
    init?(name: String, photo: UIImage?, school: String, medical: String) {
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        //self.school = ""
        //self.medical = ""
        self.school = school
        self.medical = medical
        if name.isEmpty {
            return nil
        }
    }
}
