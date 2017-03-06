//
//  ChaperoneStudentTableViewCell.swift
//  sample
//
//  Created by Subie Madhavan on 3/5/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import Foundation

class ChaperoneStudentTableViewCell: UITableViewCell {
    //MARK: Properties
    @IBOutlet weak var studentName: UILabel!
    @IBOutlet weak var studentStatus: UILabel!
    @IBOutlet weak var studentInfo: UILabel!
    @IBOutlet weak var studentPhoto: UIImageView!
    
    @IBOutlet weak var statusButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
        
        // Configure the view for the selected state
    }
}
