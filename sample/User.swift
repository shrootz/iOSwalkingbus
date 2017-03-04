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
    var name: String?
    var phoneNumber: String?
    var email: String?
    var photoUrl: String?
    
    init?(userAuthId: String, name: String, phoneNumber: String, email: String, photoUrl: String){
        self.userAuthId = userAuthId
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.photoUrl = photoUrl
    }
    
    func update(name: String?, phoneNumber: String?, email: String?){
        self.name = name ?? ""
        self.phoneNumber = phoneNumber ?? ""
        self.email = email ?? ""
    }
    
}
