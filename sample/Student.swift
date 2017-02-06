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

    // MARK: Initialization
    
    init?(name: String, photo: UIImage?, school: String, notes: String) {
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.school = school
        self.notes = notes
        if name.isEmpty {
            return nil
        }
    }
}
