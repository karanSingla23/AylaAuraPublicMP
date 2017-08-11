//
//  Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import MessageUI
import UIKit
import iOS_AylaSDK
import PDKeychainBindingsController
import SAMKeychain
import CoreTelephony

class MeTVController: UITableViewController, MFMailComposeViewControllerDelegate {
    private let logTag = "MeTVController"
    let sessionManager: AylaSessionManager?
    
    fileprivate enum Selection:Int {
        case aboutAura = 0
        case myProfile
        case emaiLogs
        case configurationWizard
        case logout
    }
    
    required init?(coder aDecoder: NSCoder) {
        sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
        super.init(coder: aDecoder)
    }

    fileprivate func logout() {
        let settings = AylaNetworks.shared().systemSettings
        let username = PDKeychainBindings.shared().string(forKey: AuraUsernameKeychainKey)
        SAMKeychain.deletePassword(forService: settings.appId, account: username!)
        if let manager = sessionManager {
            manager.shutDown(success: { () -> Void in
                do {
                    try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username!)
                } catch _ {
                    AylaLogE(tag: self.logTag, flag: 0, message:"Failed to remove cached authorization")
                }
                self.navigationController?.tabBarController?.dismiss(animated: true, completion: { () -> Void in
                });
                }, failure: { (error) -> Void in
                    AylaLogE(tag: self.logTag, flag: 0, message:"Log out operation failed: \(error)")
                    func alertWithLogout (_ message: String!, buttonTitle: String!){
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
                        let okAction = UIAlertAction (title: buttonTitle, style: UIAlertActionStyle.default, handler: { (action) -> Void in
                            do {
                                try SAMKeychain.setObject(nil, forService:"LANLoginAuthorization", account: username!)
                            } catch _ {
                                AylaLogE(tag: self.logTag, flag: 0, message:"Failed to remove cached authorization")
                            }
                            self.navigationController?.dismiss(animated: true, completion: { () -> Void in
                            });
                        })
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    switch (error as NSError).code {
                    case AylaHTTPErrorCode.lostConnectivity.rawValue:
                        alertWithLogout("Your connection to the internet appears to be offline.  Could not log out properly.", buttonTitle: "Continue")
                    default:
                        alertWithLogout("An error has occurred.\n" + error.aylaServiceDescription, buttonTitle: "Continue")

                    }
            })
        }
        
        // If we use Google Sign In, we also need sign out from SDK
        if (sessionManager?.authProvider.isKind(of: AylaGoogleOAuthProvider.self))! {
            GIDSignIn.sharedInstance().signOut()
        }
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
    
    fileprivate func customOEMConfigs() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let developOptionsVC = storyboard.instantiateViewController(withIdentifier: "DeveloperOptionsViewController") as! DeveloperOptionsViewController
        //let naviVC = UINavigationController(rootViewController: developOptionsVC)
        developOptionsVC.currentConfig = AuraConfig.currentConfig()
        self.navigationController?.pushViewController(developOptionsVC, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selection = Selection(rawValue: indexPath.section)
            else {
                AylaLogD(tag: logTag, flag: 0, message:"Unknown indexPath in `Me`")
                return
        }
        switch selection {
        case .aboutAura:
            return
        case .myProfile:
            return
        case .configurationWizard:
            customOEMConfigs()
        case .emaiLogs:
            emailLogs()
        case .logout:
            logout()
        }
    }
    
    // MARK - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
