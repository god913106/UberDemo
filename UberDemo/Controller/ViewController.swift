//
//  ViewController.swift
//  UberDemo
//
//  Created by 洋蔥胖 on 2018/7/25.
//  Copyright © 2018年 ChrisYoung. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleMobileAds

class ViewController: UIViewController {
    
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var riderDriverSwitch: UISwitch!
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var bottomButton: UIButton!
    
    var signUpMode = true
    //全營幕廣告
    var interstitial: GADInterstitial!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //https://developers.google.com/admob/ios/test-ads?authuser=0
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        let request = GADRequest()
        interstitial.load(request)
    }

    func displayAlert(title:String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func topTapped(_ sender: Any) {
        
        if emailTextField.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Missing Information", message: "You must provide both a email and password")
        } else {
            if let email = emailTextField.text {
                if let password = passwordTextField.text {
                    if signUpMode {
                        // SIGN UP
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            } else {
                                
                                if self.riderDriverSwitch.isOn {
                                    //司機
                                    let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                    req?.displayName = "Driver"
                                    req?.commitChanges(completion: nil)
                                    self.performSegue(withIdentifier: "driverSegue", sender: nil)
                                    
                                }else {
                                   //客人
                                    let req = Auth.auth().currentUser?.createProfileChangeRequest()
                                    req?.displayName = "Rider"
                                    req?.commitChanges(completion: nil)
                                    self.performSegue(withIdentifier: "riderSegue", sender: nil)
                                }
                                
                            }
                        })
                    } else {
                        // LOG IN
                        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            } else {
                                if user?.user.displayName == "Driver" {
                                    // 司機
                                    print("司機")
                                    self.performSegue(withIdentifier: "driverSegue", sender: nil)
                                } else {
                                    // 客人
                                    self.performSegue(withIdentifier: "riderSegue", sender: nil)
                                }
                            }
                        })
                    }
                }
            }
        }
        
    }
    
    @IBAction func bottomTapped(_ sender: Any) {
        
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("廣告還沒準備好")
        }
        
        if signUpMode {
            topButton.setTitle("登錄", for: .normal)
            bottomButton.setTitle("註冊", for: .normal)
            riderLabel.isHidden = true
            driverLabel.isHidden = true
            riderDriverSwitch.isHidden = true
            signUpMode = false
        } else {
            topButton.setTitle("註冊", for: .normal)
            bottomButton.setTitle("登錄", for: .normal)
            riderLabel.isHidden = false
            driverLabel.isHidden = false
            riderDriverSwitch.isHidden = false
            signUpMode = true
        }
        
    }
    
}

