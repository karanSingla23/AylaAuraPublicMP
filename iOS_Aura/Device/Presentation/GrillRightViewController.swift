//
//  GrillRightViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 12/29/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class GrillRightViewController: UIViewController, AylaDeviceListener {
    private let logTag = "GrillRightViewController"
    static let sensor1Segue = "Sensor1Segue"
    static let sensor2Segue = "Sensor2Segue"
    /// Id of a segue which is linked to device page.
    static let segueIdToDevice = "toDeviceDetailsPage"
    
    var sensor1VC: GrillRightSensorViewController!
    var sensor2VC: GrillRightSensorViewController!
    
    var device: GrillRightDevice! {
        didSet {
            self.device.add(self)
        }
    }
    var sharesModel: DeviceSharesModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let info = UIBarButtonItem(barButtonSystemItem:.action, target: self, action: #selector(GrillRightViewController.showDeviceDetails))
        self.navigationItem.rightBarButtonItem = info
    }
    
    func showDeviceDetails(){
        performSegue(withIdentifier: GrillRightViewController.segueIdToDevice, sender: self.device)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case GrillRightViewController.sensor1Segue:
                let sensorController = segue.destination as! GrillRightSensorViewController
                sensorController.sensor = device.channel1
                sensorController.device = device
                sensor1VC = sensorController
            case GrillRightViewController.sensor2Segue:
                let sensorController = segue.destination as! GrillRightSensorViewController
                sensorController.sensor = device.channel2
                sensorController.device = device
                sensor2VC = sensorController
            case GrillRightViewController.segueIdToDevice: // To device page
                if let device = sender as? AylaDevice {
                    let detailsController = segue.destination as! DeviceViewController
                    detailsController.device = device
                    detailsController.sharesModel = self.sharesModel
                }
            default:
                break;
            }
        }
    }
    
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
        if let change = change as? AylaPropertyChange {
            switch change.property.name {
            case (let n) where n.contains("00:"):
                sensor1VC.refreshUI(change)
            case (let n) where n.contains("01:"):
                sensor2VC.refreshUI(change)
            default:
                break;
            }
        } else if let change = change as? AylaDeviceChange, let device = change.device as? GrillRightDevice {
            if device.dsn == self.device.dsn {
                sensor1VC.controlsShouldEnable(forDevice: device)
                sensor2VC.controlsShouldEnable(forDevice: device)
            }
        }
    }
    
    func device(_ device: AylaDevice, didFail error: Error) {
        AylaLogE(tag: logTag, flag: 0, message:"Error: \(error)")
    }

}
