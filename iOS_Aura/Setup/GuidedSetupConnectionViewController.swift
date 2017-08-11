//
//  GuidedSetupConnectionViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/18/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class GuidedSetupConnectionViewController: UIViewController {
    struct Constants {
        enum Segue : String {
            case goToWiFiSelection = "GoToWiFiSelectionSegue"
        }
    }
    let model = GuidedSetupModel(withSetup: AylaSetup(sdkRoot: AylaNetworks.shared()))
    var setupNavigationController : GuidedSetupNavigationController? {
        get {
            return self.navigationController as? GuidedSetupNavigationController
        }
    }
    @IBAction func cancelAction(_ sender: Any) {
        self.model.cancel()
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if model.isConnectedToDeviceAP {
            checkDeviceConnection()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goToSettingsAction(_ sender: Any) {
        goToWiFiSettings()
    }
    
    
    func checkDeviceConnection() {
        self.setupNavigationController?.displayProgressView(animated: true, completion: {
            self.setupNavigationController?.modalProgress.textLabel?.text = "Opening Connection to EVB"
            self.model.connect(toNewDevice: { (setupDevice) in
                self.setupNavigationController?.hideProgressView(animated: true, completion: {
                    self.performSegue(withIdentifier: Constants.Segue.goToWiFiSelection.rawValue, sender: nil)
                })
            }) { (error) in
                self.setupNavigationController?.hideProgressView(animated: true, completion: {
                    if !self.model.isConnectedToDeviceAP {
                        UIAlertController.alert("Connection Error",
                                                message: "Your phone has disconnected from the device AP.\n\nPlease verify the Wi-Fi connection in the Settings app.",
                                                buttonTitle: "OK",
                                                fromController: self,
                                                okHandler: { (action) in
                                                    self.navigationController?.popViewController(animated: true)
                        })
                    } else {
                        UIAlertController.alert("Connection Error",
                                                message: error.aylaServiceDescription + "\n\n If problem persists, please reset the EVB and try again.",
                                                buttonTitle: "OK",
                                                fromController: self,
                                                okHandler: { (action) in
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                })
            }
        })
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        guard let segueIdentifier = segue.identifier, let _segue = Constants.Segue(rawValue: segueIdentifier) else {
            return
        }
        
        switch _segue {
        case .goToWiFiSelection:
            guard let selectWiFiController = segue.destination as? GuidedSetupWiFiSelection else {
                return
            }
            selectWiFiController.model = model
        }
    }

}
