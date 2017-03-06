//
//  User.swift
//  sample
//
//  Created by Subie Madhavan on 3/3/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import Foundation
import UIKit

class User {
    // MARK: Properties
    var userAuthId: String
    var routes: String
    var name: String?
    var phoneNumber: String?
    var email: String?
    var photoUrl: String?
    var students: [String]?
    var schoolsParent: [String:String]?
    
    init?(userAuthId: String, name: String, phoneNumber: String, email: String, photoUrl: String, students: [String], schoolsParent: [String:String], routes:String){
        self.userAuthId = userAuthId
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.photoUrl = photoUrl
        self.students = students
        self.schoolsParent = schoolsParent
        self.routes = routes
    }
    
    func update(name: String?, phoneNumber: String?, email: String?, schoolsParent: [String:String]){
        self.name = name ?? ""
        self.phoneNumber = phoneNumber ?? ""
        self.email = email ?? ""
        self.schoolsParent = schoolsParent
    }
    
}
