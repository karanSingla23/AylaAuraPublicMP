//
//  Aura
//
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import PDKeychainBindingsController
import SAMKeychain
import CoreTelephony

class AboutAuraTableViewController: UITableViewController {
    private let logTag = "AboutAuraTableViewContoller"
    fileprivate var user: AylaUser?
    fileprivate let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)

    @IBOutlet fileprivate weak var auraVersionLabel: UILabel!
    @IBOutlet fileprivate weak var sdkVersionLabel: UILabel!
    @IBOutlet fileprivate weak var configNameLabel: UILabel!
    
    @IBOutlet fileprivate weak var phoneModelLabel: UILabel!
    @IBOutlet fileprivate weak var iOSVersionLabel: UILabel!
    @IBOutlet fileprivate weak var carrierNameLabel: UILabel!
    @IBOutlet fileprivate weak var languageLabel: UILabel!
    @IBOutlet fileprivate weak var countryLabel: UILabel!
    @IBOutlet fileprivate weak var timeZoneLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = sessionManager?.fetchUserProfile({ (user) in
            self.user = user
            
            }, failure: { (error) in
                AylaLogE(tag: self.logTag, flag: 0, message:"Error : \(error)")
                UIAlertController.alert("Error", message: error.aylaServiceDescription, buttonTitle: "OK", fromController: self)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateUI()
    }
    
    fileprivate func populateUI() {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let carrier = CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName
        let deviceModel = self.getDeviceModel()
        let osVersion = UIDevice.current.systemVersion
        let country = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
        let language = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as! String
        let configName = AuraConfig.currentConfig().name
        let timeZone = TimeZone.autoupdatingCurrent.identifier
        
        auraVersionLabel.text = appVersion
        sdkVersionLabel.text = AYLA_SDK_VERSION
        configNameLabel.text = configName
        phoneModelLabel.text = deviceModel
        iOSVersionLabel.text = osVersion
        carrierNameLabel.text = carrier
        languageLabel.text = language
        countryLabel.text = country
        timeZoneLabel.text = timeZone
    }
    
    fileprivate func getDeviceModel () -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafeMutablePointer(to: &systemInfo.machine) {
            ptr in String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        return modelCode
    }
    
    fileprivate func customOEMConfigs() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let developOptionsVC = storyboard.instantiateViewController(withIdentifier: "DeveloperOptionsViewController") as! DeveloperOptionsViewController
        let naviVC = UINavigationController(rootViewController: developOptionsVC)
        developOptionsVC.parentVC = self
        self.navigationController?.present(naviVC, animated: true, completion: { })
    }
    
    func logOutNow(){
        self.navigationController?.dismiss(animated: true, completion: {})
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let configIndexPath = IndexPath(row: 2, section: 0)
        if indexPath == configIndexPath {
            customOEMConfigs()
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
