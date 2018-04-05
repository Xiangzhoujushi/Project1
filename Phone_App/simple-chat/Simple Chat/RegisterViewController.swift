//
//  RegisterViewController.swift
//  Simple Chat
//
//  Created by Zhenyang Yu on 4/4/18.
//  Copyright © 2018 Glenn R. Fisher. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var RegisterUsername: UITextField!
    @IBOutlet weak var RegisterPassword: UITextField!
    @IBOutlet weak var RegisterPassword2: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    
    @IBAction func doRegister(_ sender: Any) {
        let username = RegisterUsername.text
        let password = RegisterPassword.text
        let password2 = RegisterPassword2.text
        
        if ((username?.isEmpty)! || (password?.isEmpty)! || (password2?.isEmpty)!){
            displayAlert(userMessage: "All fields have to be filled!")
            return
        }
        
        if (password != password2){
            displayAlert(userMessage: "Passwords don't match!")
            return
        }
        let defaults = UserDefaults.standard
        defaults.set(password, forKey: "pass")
        defaults.set(username, forKey: "user")
    }
    
    func displayAlert (userMessage : String){
        let myAlert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        
        myAlert.addAction(okAction)
        self.present(myAlert, animated: true, completion: nil)
    }
    

    
}
