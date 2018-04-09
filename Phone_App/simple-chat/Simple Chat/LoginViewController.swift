//
//  LoginViewController.swift
//  Simple Chat
//
//  Created by Peiyuan Tang on 2018/3/29.
//  Copyright © 2018年 Glenn R. Fisher. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController {

    @IBOutlet weak var username_input: UITextField!
    @IBOutlet weak var password_input: UITextField!
    @IBOutlet weak var login_button: UIButton!
    
    
    @IBOutlet weak var GifView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // register the user
        GifView.loadGif(name: "ezgif.com-video-to-gif")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        //create the context
        didTapLoginButton(login_button)
    }

    
    @IBAction func didTapLoginButton(_ sender: UIButton) {
        // Regular login attempt. Add the code to handle the login by email and password.
        let user = username_input.text
        let pass = password_input.text
//        input(userr: user!, passs: pass!)
        if let regis = UserDefaults.standard.array(forKey: "login"){
            let regis = regis as! [[String]]
            print(regis)
            for (index, element) in regis.enumerated() {
                print(regis[index][0])
                if(user == regis[index][0] && pass == regis[index][1]){
                    print(regis[index])
                    gotoLogin(sender: login_button)
    
                }
        
            }
        }
    }


   @IBAction func gotoLogin (sender: UIButton!) {

        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DirectionView") as! DirectionViewController

        self.present(nextViewController, animated:true, completion:nil)

    }
    
    func displayAlert (userMessage : String){
        let myAlert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        
        myAlert.addAction(okAction)
        self.present(myAlert, animated: true, completion: nil)
    }


}
