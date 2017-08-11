//
//  LogFunctions.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 3/9/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import Foundation

import Foundation
import iOS_AylaSDK

public func AylaLogI(tag: String, flag: Int, message: String) {
    AylaLogManager.shared().log(tag, level:AylaLogMessageLevel.info, flag:flag, time:nil, message: message)
}
public func AylaLogW(tag: String, flag: Int, message: String) {
    AylaLogManager.shared().log(tag, level:AylaLogMessageLevel.warning, flag:flag, time:nil, message: message)
}
public func AylaLogE(tag: String, flag: Int, message: String) {
    AylaLogManager.shared().log(tag, level:AylaLogMessageLevel.error, flag:flag, time:nil, message: message)
}
public func AylaLogD(tag: String, flag: Int, message: String) {
    AylaLogManager.shared().log(tag, level:AylaLogMessageLevel.debug, flag:flag, time:nil, message: message)
}
public func AylaLogV(tag: String, flag: Int, message: String) {
    AylaLogManager.shared().log(tag, level:AylaLogMessageLevel.verbose, flag:flag, time:nil, message: message)
}
