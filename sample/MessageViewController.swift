//
//  MessageViewController.swift
//  sample
//
//  Created by Subie Madhavan on 3/28/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import MessageUI

class MessageViewController: UIViewController,MFMessageComposeViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        sendMessage()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult){
        switch (result) {
        case MessageComposeResult.cancelled:
            break
        case MessageComposeResult.failed:
            break
        case MessageComposeResult.sent:
            break
        default:
            break
        }
        self.dismiss(animated: true) { () -> Void in
        }
    }

    func sendMessage() {
        let messageVC = MFMessageComposeViewController()
        messageVC.body = "My first custom SMS";
        messageVC.recipients = ["0123456789"]
        messageVC.messageComposeDelegate = self;
        self.present(messageVC, animated: false, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
