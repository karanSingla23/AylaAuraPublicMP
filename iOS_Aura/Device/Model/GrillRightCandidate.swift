//
//  GrillRightCandidate.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 12/23/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK


/// GrillRight off the shelff device doesn't implement an Ayla GATT Service, therefore all characteristics in service must be hardcoded, for the hardwareAddress, returning the local UUID
class GrillRightCandidate: AylaBLECandidate {
    override var productName: String? {
        return GrillRightDevice.GRILL_RIGHT_DEFAULT_NAME
    }
    override var model: String? {
        get {
            return GrillRightDevice.GRILL_RIGHT_MODEL
        }
        set {
        }
    }
    override var oemModel: String? {
        get {
            return GrillRightDevice.GRILL_RIGHT_OEM_MODEL
        }
        set {
        }
    }
    override var dsn: String? {
        get {
            return self.hardwareAddress
        }
        set {
        }
    }
    
    override var hardwareAddress: String? {
        get {
            return peripheral.identifier.uuidString
        }
        set {
        }
    }
    
    func oem() -> String {
        return "0dfc7900"
    }
    
    override var swVersion: String! {
        get {
            return "1.0"
        }
        set {
        }
    }
    override var subdevices: [AylaLocalRegistrationCandidateSubdevice]? {
        get {
            var subdevices = [AylaLocalRegistrationCandidateSubdevice]()
            for i in 0...1 {
                let subdevice = AylaLocalRegistrationCandidateSubdevice()
                subdevice.subdevice_key = String(format: "%02d", i)
                
                let template = AylaLocalRegistrationCandidateTemplate()
                template.template_key = "grillrt"
                template.version = "1.1"
                
                subdevice.templates = [template]
                
                subdevices.append(subdevice)
            }
            return subdevices
        }
        set {
            
        }
    }
}
