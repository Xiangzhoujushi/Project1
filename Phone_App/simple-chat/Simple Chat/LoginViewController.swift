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
//        print(user,pass)
//        if(user == "hexie"&&pass == "fuqiang"){
//        login_button.addTarget(self, action: #selector(gotoLogin), for: .touchUpInside)
//        login_button.addTarget(self, action: #selector(gotoLogin), for: .touchUpOutside)
//        }

//        let context = appDelegate.persistentContainer.viewContext
        // Do any additional setup after loading the view.
    }

    
    @IBAction func didTapLoginButton(_ sender: UIButton) {
        // Regular login attempt. Add the code to handle the login by email and password.
        let user = username_input.text
        let pass = password_input.text
        input(userr: user!, passs: pass!)
    }

    func input(userr : String, passs: String){
        let user_reg = UserDefaults.standard.string(forKey: "user")
        let user_pass = UserDefaults.standard.string(forKey: "pass")

        if(userr == user_reg && passs == user_pass){
//            login_button.addTarget(self, action: #selector(gotoLogin), for: .touchUpInside)
//            login_button.addTarget(self, action: #selector(gotoLogin), for: .touchUpOutside)
            gotoLogin(sender: login_button)
        }
    }
    @IBAction func gotoLogin (sender: UIButton!) {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "DirectionView") as! DirectionViewController
        
        self.present(nextViewController, animated:true, completion:nil)
        
    }


}
