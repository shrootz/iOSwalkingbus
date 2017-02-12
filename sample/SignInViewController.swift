//
//  SignInViewController.swift
//  sample
//
//  Created by Subie Madhavan on 2/10/17.
//  Copyright © 2017 seniordesign. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignInViewController: UIViewController, GIDSignInUIDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: "home_screen", sender: nil)
            }
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GIDSignIn.sharedInstance().uiDelegate = self
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
