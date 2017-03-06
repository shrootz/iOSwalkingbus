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
    var schoolName: String
    var info: String
    var photo: UIImage?
    var bluetooth: String
    var schedule: [String: [String]]
    var studentDatabaseId: String
    var schoolDatabaseId: String
    
    // MARK: Initialization
    
    init?(name: String, photo: UIImage?, schoolName: String, info: String, schedule: [String: [String]], studentDatabaseId: String, schoolDatabaseId: String, bluetooth: String) {
        // Initialize stored properties.
        self.name = name
        self.photo = photo
        self.schoolName = schoolName
        self.info = info
        self.schedule = schedule
        self.studentDatabaseId = studentDatabaseId
        self.schoolDatabaseId = schoolDatabaseId
        self.bluetooth = bluetooth
        if name.isEmpty && schoolName.isEmpty {
            return nil
        }
    }
    
}

extension Student: Equatable {}

func ==(lhs: Student, rhs: Student) -> Bool {
    return lhs.studentDatabaseId == rhs.studentDatabaseId
}
