//
//  MenuTableViewController.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 5/8/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import SAMKeychain
import PDKeychainBindingsController
import MessageUI
import CoreTelephony

fileprivate let logTag = "MenuTableViewController"
class MenuTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    var sessionManager: AylaSessionManager? {
        return AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
    }
    @IBOutlet weak var auraVersionLabel: UILabel!
    var headerTouch: Int = 0
    fileprivate enum Section :Int {
        case header
        case devices
        case account
        case support
        case sectionCount
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        self.auraVersionLabel.text = "Aura version \(appVersion)"
    }
    
    fileprivate func logout() {
        func backToLoginScreen(){
            self.sideMenuController?.dismiss(animated: true, completion: {
                self.sideMenuController?.centerViewController?.navigationController?.dismiss(animated: true, completion: { () -> Void in });
            })
        }

        func performLogout(){
            let settings = AylaNetworks.shared().systemSettings
            let username = PDKeychainBindings.shared().string(forKey: AuraUsernameKeychainKey)
            SAMKeychain.deletePassword(forService: settings.appId, account: username!)
            if let manager = sessionManager {
                manager.shutDown(success: { () -> Void in
                    do {
                        try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username!)
                    } catch _ {
                        AylaLogE(tag: logTag, flag: 0, message:"Failed to remove cached authorization")
                    }
                    backToLoginScreen()
                    
                }, failure: { (error) -> Void in
                    AylaLogE(tag: logTag, flag: 0, message:"Log out operation failed: \(error)")
                    func alertWithLogout (_ message: String!, buttonTitle: String!){
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction (title: buttonTitle, style: UIAlertActionStyle.default, handler: { (action) -> Void in
                            do {
                                try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username!)
                            } catch _ {
                                AylaLogE(tag: logTag, flag: 0, message:"Failed to remove cached authorization")
                            }
                            backToLoginScreen()
                        })
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: { 
                            backToLoginScreen()
                        })
                    }
                    switch (error as NSError).code {
                    case AylaHTTPErrorCode.lostConnectivity.rawValue:
                        alertWithLogout("Your connection to the internet appears to be offline.  Could not log out properly.", buttonTitle: "Continue")
                    default:
                        alertWithLogout("An error has occurred.\n" + error.aylaServiceDescription, buttonTitle: "Continue")
                        
                    }
                })
            }
            else {
                backToLoginScreen()
            }
            
            // If we use Google Sign In, we also need sign out from SDK
            if let sessionManager = sessionManager, sessionManager.authProvider.isKind(of: AylaGoogleOAuthProvider.self) {
                GIDSignIn.sharedInstance().signOut()
            }
        }
        
        UIAlertController.alert("Continue?", message: "Are you sure you want to sign out?", okayButtonTitle: "Continue", cancelButtonTitle: nil, fromController: self, okHandler: { (action) in
            performLogout()
        }) { (action) in }
    }
    
    fileprivate func getDeviceModel () -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafeMutablePointer(to: &systemInfo.machine) {
            ptr in String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        return modelCode
    }
    
    fileprivate func removeOptionalStrings(_ inputText :String) -> String {
        return inputText.replacingOccurrences(of: "Optional(\"", with: "").replacingOccurrences(of: "\")", with: "")
    }
    
    fileprivate func emailLogs() {
        let mailVC = MFMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            if let filePath = AylaLogManager.shared().getLogFilePath() {
                let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
                mailVC.setToRecipients([AylaNetworks.getSupportEmailAddress()])
                mailVC.setSubject("iOS SDK Log (\(AylaNetworks.getVersion()))")
                
                let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                let carrier = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName
                let deviceModel = self.getDeviceModel()
                let osVersion = UIDevice.current.systemVersion
                let country = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
                let language = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as! String
                
                var emailMessageBody = "Latest logs from Aura app attached\n\nAura config name:\(AuraConfig.currentConfig().name)\nDevice Model: \(deviceModel ?? "nil")\nOS Version: \(osVersion)\nCountry: \(country)\nLanguage: \(language)\nNetwork Operator: \(carrier ?? "nil")\nAyla SDK version: \(AYLA_SDK_VERSION)\nAura app version: \(appVersion)"
                emailMessageBody = self.removeOptionalStrings(emailMessageBody)
                mailVC.setMessageBody(emailMessageBody, isHTML: false)
                if data != nil {
                    mailVC.addAttachmentData(data!, mimeType: "application/plain", fileName: "sdk_log")
                }
                mailVC.mailComposeDelegate = self
                
                present(mailVC, animated: true, completion: nil)
            }
            else  {
                UIAlertController.alert(nil, message: "No log file found.", buttonTitle: "Got it", fromController: self)
            }
        }
        else  {
            UIAlertController.alert(nil, message: "Unable to send an email.", buttonTitle: "Got it", fromController: self)
        }
    }
                        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case Section.header.rawValue:
            headerTouch += 1
            tableView.deselectRow(at: indexPath, animated: false)
            if headerTouch == 10 {
                UIAlertController.alert("Thanks for using Aura! 🐿", message: nil, buttonTitle: "You're quite welcome.", fromController: self, okHandler: { (action) in })
            }
        case Section.devices.rawValue:
            switch indexPath.row {
            case 0:
                sideMenuController?.performSegue(withIdentifier: "embedCenterController", sender: nil)
            case 1:
                sideMenuController?.performSegue(withIdentifier: "embedSharesController", sender: nil)
            default:
                break
            }
        case Section.account.rawValue:
            switch indexPath.row {
            case 0:
                sideMenuController?.performSegue(withIdentifier: "embedAccountInformationController", sender: nil)
            case 1:
                logout()
            default:
                break
            }
        case Section.support.rawValue:
            switch indexPath.row {
            case 0:
                emailLogs()
            case 1:
                sideMenuController?.performSegue(withIdentifier: "embedAboutController", sender: nil)
            default:
                break
            }
        default:
            break
        }
    }

    // MARK - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
