//
//  debug.swift
//  sample
//
//  Created by Subie Madhavan on 2/5/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import Foundation
import UIKit

extension NSLayoutConstraint {
    
    override open var description: String {
        let id = identifier ?? ""
        return "id: \(id), constant: \(constant)" //you may print whatever you want here
    }
}
