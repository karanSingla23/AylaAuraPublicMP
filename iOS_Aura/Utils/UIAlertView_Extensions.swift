//
//  UIAlertView_Extensions.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
extension UIAlertController {
    class func alert(_ title: String?, message: String?, buttonTitle: String?, fromController controller: UIViewController, okHandler: @escaping (UIAlertAction)->Void = { _ in }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction (title: buttonTitle ?? "Okay", style: UIAlertActionStyle.default, handler:okHandler)
        alert.addAction(okAction)
        controller.present(alert, animated: true, completion: nil)
    }
    class func alert(_ title: String?, message: String?, okayButtonTitle: String?, cancelButtonTitle: String?,fromController controller: UIViewController, okHandler: @escaping (UIAlertAction)->Void = { _ in }, cancelHandler: @escaping (UIAlertAction)->Void = { _ in }) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction (title: okayButtonTitle ?? "Okay", style: UIAlertActionStyle.default, handler:okHandler)
        let cancelAction = UIAlertAction (title: cancelButtonTitle ?? "Cancel", style: UIAlertActionStyle.cancel, handler:cancelHandler)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        controller.present(alert, animated: true, completion: nil)
    }
}
