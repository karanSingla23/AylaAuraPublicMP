//
//  AylaGenericThermostatCandidate.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 3/14/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class AylaGenericThermostatCandidate: AylaBLECandidate {
    func oem() -> String {
        return "0dfc7900"
    }
    
    override var model: String? {
        get {
            return AylaGenericThermostatDevice.BLE_TSTAT_MODEL
        }
        set {
            super.model = newValue
        }
    }
    override var subdevices: [AylaLocalRegistrationCandidateSubdevice]? {
        get {
            let template = AylaLocalRegistrationCandidateTemplate()
            template.template_key = "bletstat";
            template.version = "1.2";
            
            let subdevice = AylaLocalRegistrationCandidateSubdevice()
            subdevice.subdevice_key = String(format:"%02d",0)
            subdevice.templates = [template]
            
            return [subdevice]
        }
        set {
            super.subdevices = newValue
        }
    }
    
}
