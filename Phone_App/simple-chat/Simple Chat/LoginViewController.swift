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

    @IBOutlet weak var GifView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // register the user
        GifView.loadGif(name: "ezgif.com-video-to-gif")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        //create the context
        

//        let context = appDelegate.persistentContainer.viewContext
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
