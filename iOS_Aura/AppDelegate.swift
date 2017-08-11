//
//  AppDelegate.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/17/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var auraSessionListener : AuraSessionListener?
    private let logTag = "AppDelegate"
    var deviceTokenString : String = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        configureUIAppearance()
        
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            if url.isFileURL {
                AylaLogI(tag: logTag, flag: 0, message:"Aura config file opened.")
            }
        }

        // Setup core manager
        let settings = AylaSystemSettings.default()
        
        // settings from AuraConfig
        AuraConfig.currentConfig().applyTo(settings)

        // Set device detail provider
        settings.deviceDetailProvider = DeviceDetailProvider()
        
        // Set DSS as allowed
        settings.allowDSS = true;
        
        // Uncomment following line to allow Offline use
        //settings.allowOfflineUse = true
        
        // Init device manager
        AylaNetworks.initialize(settings, withLocalDevices: true)
        
        AylaLogManager.shared().loggingLevel = .debug
        
        AylaNetworks.enableNetworkProfiler()
        
        
        UIBarButtonItem.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor.auraTintColor()
        AuraButton.appearance().backgroundColor = UIColor.aylaButtonBlue()
        GreenButton.appearance().backgroundColor = UIColor.auraTintColor()
        GreenView.appearance().backgroundColor = UIColor.auraTintColor()
        UILabel.appearance(whenContainedInInstancesOf: [GreenView.self]).textColor = UIColor.white
        
        setupGoogleSignIn()
        
        registerForPushNotifications(application: application)
        
        // Register Wechat App
        #if INCLUDE_WECHAT_OAUTH
            WXApi.registerApp(AuraOptions.WechatAppId)
        #endif
//            let trigger = AylaPropertyTrigger()
//           trigger.propertyNickname = "Blue Button"
        return true
    }
    
    // Set Aura application styling
    func configureUIAppearance() {
        
        UITabBar.appearance().tintColor = UIColor.auraTintColor()
        UINavigationBar.appearance().barTintColor = UIColor.auraTintColor()
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 17), NSForegroundColorAttributeName: UIColor.white]
        GreenButton.appearance().backgroundColor = UIColor.auraTintColor()
        GreenButton.appearance().tintColor = UIColor.white

    }
    
    /// Initialize Google sign-in
    func setupGoogleSignIn() {
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(String(describing: configureError))")
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            let dict = NSDictionary(contentsOfFile: path)
            GIDSignIn.sharedInstance().serverClientID = dict!["SERVER_CLIENT_ID"] as! String
        }
    }
    
    // Instantiate and display a UIAlertViewController as needed
    func presentAlertController(_ title: String?, message: String?, withOkayButton: Bool, withCancelButton: Bool, okayHandler: (() -> Void)?, cancelHandler: (() -> Void)?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        if withOkayButton {
            let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler:{(action) -> Void in
                if let okayHandler = okayHandler{
                    okayHandler()
                }
            })
            alert.addAction(okAction)
            if withCancelButton {
                let cancelAction = UIAlertAction (title: "Cancel", style: UIAlertActionStyle.cancel, handler:{(action) -> Void in
                    if let cancelHandler = cancelHandler{
                        cancelHandler()
                    }
                })
                alert.addAction(cancelAction)
            }
            displayViewController(alert)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        // Aura Config
        if url.isFileURL && url.pathExtension == "auraconfig" {
            let fileManager = FileManager.default
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let filePath = paths[0].appendingPathComponent(url.lastPathComponent)
            do {
                try fileManager.moveItem(at: url, to: filePath)
            } catch _ {
                UIAlertController.alert("Error", message: "Failed to import file, it won't be available later from configurations list", buttonTitle: "OK", fromController: (self.window?.rootViewController)!)
            }
            
            openConfigAtURL(filePath)
            
            return true
        }
        
        // Google Sign In
        if GIDSignIn.sharedInstance().handle(url,
                                             sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                             annotation: options[UIApplicationOpenURLOptionsKey.annotation]) {
            return true
        }
        
        // Handle Wechat OAuth URLs
        #if INCLUDE_WECHAT_OAUTH
        if WXApi.handleOpen(url, delegate: self) {
            return true
        }
        #endif
        
        // Parse URL app was launched with
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryitems = components?.queryItems
        
        // If URL is sent from WI-Fi Setup Screen
        if url.host == "wifi_setup" {
            
            // Pull DSN from URL
            let dsnParam = queryitems?.filter({$0.name == "dsn"}).first
            let dsn = dsnParam?.value
            AylaLogD(tag: logTag, flag: 0, message:"Will Setup Wi-Fi for DSN: \(dsn ?? "nil")")
            
            let topVC = topViewController()
            
            if let setupController = topVC as? GuidedSetupConnectionViewController {
                setupController.checkDeviceConnection()
            } else if let loginVC = topVC as? LoginViewController {
                //Display error indicating device is connected to a different network
                let setupAlert = UIAlertController(title: "Perform Wi-Fi Setup?", message: "You do not appear to be logged in.\n\nYou may set up the device's Wi-Fi using the advanced setup flow, but you may wish to log in with an Ayla account first. ", preferredStyle: .alert)
                setupAlert.addAction(UIAlertAction(title: "Go To Settings", style: .default, handler: { (alert) in
                    goToWiFiSettings()
                }))
                setupAlert.addAction(UIAlertAction(title: "Advanced Setup", style: .default, handler: { (alert) in
                    // Instantiate and Push the advanced SetupViewController
                    let setupStoryboard: UIStoryboard = UIStoryboard(name: "SetupOld", bundle: nil)
                    let setupVC = setupStoryboard.instantiateInitialViewController()
                    self.displayViewController(setupVC!)
                }))
                setupAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert) in
                }))
                
                loginVC.present(setupAlert, animated: true, completion: nil)
            } else {
                // Instantiate and Push SetupViewController
                let setupStoryboard: UIStoryboard = UIStoryboard(name: "GuidedSetup", bundle: nil)
                let setupVC = setupStoryboard.instantiateInitialViewController()
                self.displayViewController(setupVC!)
            }
        }
        // If URL is from an Account Confirmation Email
        else if url.host == "user_sign_up_token" {
            
            // Pull Token from URL
            let tokenParam = queryitems?.filter({$0.name == "token"}).first;
            let token = tokenParam?.value;
            AylaLogD(tag: logTag, flag: 0, message:"Will Confirm Sign Up with Token: \(token ?? "nil")")
            
            presentAlertController("Account Confirmation",
                                   message: "Would you like to confirm to this account?",
                                   withOkayButton: true,
                                   withCancelButton: true,
                                   okayHandler:{(action) -> Void in
                                    
                                    // Get LoginManager and send account confirmation token
                                    let loginManager = AylaNetworks.shared().loginManager
                                    loginManager.confirmAccount(withToken: (token)!, success: { () -> Void in
                                        self.presentAlertController("Account Confirmed",
                                            message: "Enter your credentials to log in",
                                            withOkayButton: true,
                                            withCancelButton: false,
                                            okayHandler:nil,
                                            cancelHandler:nil)
                                        }, failure: { (error) -> Void in
                                            self.presentAlertController("Account Confirmation Failed.",
                                                message: "Account may already be confirmed. Try logging in.",
                                                withOkayButton: true,
                                                withCancelButton: false,
                                                okayHandler:nil,
                                                cancelHandler:nil)
                                    })
 
            },cancelHandler:nil)
           
        }
        else if url.host == "user_reset_password_token" {
            
            let tokenParam = queryitems?.filter({$0.name == "token"}).first;
            
            // Instantiate and Push PasswordResetViewController
            let setupStoryboard: UIStoryboard = UIStoryboard(name: "PasswordReset", bundle: nil)
            let passwordResetNavController = setupStoryboard.instantiateInitialViewController() as! UINavigationController
            let passwordResetController = passwordResetNavController.viewControllers.first! as! PasswordResetTableViewController
            passwordResetController.passwordResetToken = tokenParam!.value! as String
            displayViewController(passwordResetNavController)
            //NSNotificationCenter.defaultCenter().postNotificationName("PasswordReset", object: tokenParam?.value)
        }
        else {
            presentAlertController("Not Yet Implemented.",
                                        message: String.localizedStringWithFormat("Cannot currently parse url with %@ parameter", url.host ?? ""),
                                        withOkayButton: true,
                                        withCancelButton: false,
                                        okayHandler:nil,
                                        cancelHandler:nil)
        }
        
        return true
    }
    
    func openConfigAtURL(_ filePath :URL) {
        if let loadedConfig = loadConfigAtURL(filePath) {
            let topVC = topViewController()
            // Handle case of already being on the correct page
            if let developOptionsVC = topVC as? DeveloperOptionsViewController {
                developOptionsVC.currentConfig = loadedConfig
                developOptionsVC.newConfigImport = true
                developOptionsVC.tableView.reloadData()
            } else {
                // Otherwise load and display a fresh one
                let storyboard = UIStoryboard(name: "Login", bundle: nil)
                let developOptionsVC = storyboard.instantiateViewController(withIdentifier: "DeveloperOptionsViewController") as! DeveloperOptionsViewController
                let naviVC = UINavigationController(rootViewController: developOptionsVC)
                developOptionsVC.currentConfig = loadedConfig
                developOptionsVC.newConfigImport = true
                self.displayViewController(naviVC)
                
                developOptionsVC.tableView.reloadData()
            }
        }

    }
    
    func loadConfigAtURL(_ filePath :URL) -> AuraConfig? {
        func deleteFile(filePath :URL){
            do {
                try FileManager.default.removeItem(at: filePath)
            } catch {
                AylaLogE(tag: logTag, flag: 0, message:"Failed to delete file")
            }
        }
        let configData = try? Data(contentsOf: filePath)
        do {
            let configJSON = try JSONSerialization.jsonObject(with: configData!, options: .allowFragments)
            guard let configDict: NSDictionary = configJSON as? NSDictionary else {
                presentAlertController("Error Loading Config Data", message: "The file appears to be invalid. Please check the file and try again.", withOkayButton: true, withCancelButton: false, okayHandler: {
                    deleteFile(filePath: filePath)
                }, cancelHandler: nil)
                return nil
            }
            AylaLogD(tag: logTag, flag: 0, message:"Aura Config: \(configDict)")
            
            let configName = configDict["name"] as! String
            return AuraConfig(name: configName, config: configDict)
        }
        catch let error as NSError {
            AylaLogE(tag: logTag, flag: 0, message:"Error: \(error)")
            let message = String(format: "Something is wrong with the config file: \n\n%@\n\nPlease check the file and try again.", error.description)
            presentAlertController("Error", message: message, withOkayButton: true, withCancelButton: false, okayHandler: {
                deleteFile(filePath: filePath)
            }, cancelHandler: nil)
            return nil
        }
    }
    
    func displayViewController(_ controller: UIViewController){
        //  VC hierarchy is different if we are logged in than if we are not.
        //  This will ensure the VC is displayed.
        let topController = topViewController()
        topController.present(controller, animated: true, completion: nil)
    }
    
    func topViewController() -> UIViewController {
        let rootController = UIApplication.shared.keyWindow?.rootViewController
        return topViewControllerFromRoot(rootController!)
    }
    
    func topViewControllerFromRoot(_ rootVC:UIViewController) ->UIViewController{
        if rootVC.isKind(of: UITabBarController.self) {
            let tabVC = rootVC as! UITabBarController
            return topViewControllerFromRoot(tabVC.selectedViewController!)
            
        } else if rootVC.isKind(of: UINavigationController.self) {
            let navC = rootVC as! UINavigationController
            
            return topViewControllerFromRoot(navC.viewControllers.last!)
            
        } else if let presentedVC = rootVC.presentedViewController {
            return topViewControllerFromRoot(presentedVC)
            
        } else {
            return rootVC
        }
    }
    
    // Called when AylaSessionManagerListener receives session closed event due to any error
    func displayLoginView() {
        
        // If topVC is already login VC, do nothing
        let topVC = topViewController()
        if topVC.isKind(of: LoginViewController.self)  {
            return;
        }
        
        // Pop all existing VCs to root. Root is Login VC
        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        rootVC?.dismiss(animated: true, completion: nil)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        AylaNetworks.shared().pause()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AylaNetworks.shared().resume()
        
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    }
    
    // MARK -
    // MARK - Push Notifications APIs

    /** Registers for user notification settings for push notifications
     * 
     * - parameter : application UIApplication object
     */
    func registerForPushNotifications(application : UIApplication) {
        let notificationSettings = UIUserNotificationSettings(types:  [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    /** Delegate method to check if user allowed the app to receive remote notifications
     *
     * - parameter : application UIApplication object
     * - parameter : notificationSettings UIUserNotificationSettings object
     */
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        guard let _ = UIApplication.shared.currentUserNotificationSettings?.types else {
            return
        }
        application.registerForRemoteNotifications()
    }
    
    /** Delegate method to notify that app registered to receive remote/push notifications
     *
     * - parameter : application UIApplication object
     * - parameter : deviceToken Data for device token
     */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        
        print(deviceToken)
        print(deviceToken.reduce("", {$0 + String(format: "%02X", $1)}))
        self.deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print(self.deviceTokenString)
     }
    
    /** Delegate method to notify that app failed to register for receiving remote/push notifications
     *
     * - parameter : application UIApplication object
     * - parameter : deviceToken Data for device token
     */
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AylaLogE(tag: logTag, flag: 0, message:"Failed to register for remote notifications. Error : \(error)")
    }
    
    /** Delegate method called when app receivesa remote notification when either in foreground or background
     *
     * - parameter : application UIApplication object
     * - parameter : userInfo Hashtable containing push notification payload
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // If app is in active state (in foreground), show notification as a alert dialog
        if(application.applicationState == UIApplicationState.active) {
            if let aps = userInfo["aps"] as? [AnyHashable : Any] {
                if let alert = aps["alert"] as? String {
                    AylaLogI(tag: logTag, flag: 0, message: "Received push notification : \(alert)")
                    
                    DispatchQueue.main.async {
                        self.presentAlertController("Notification", message: "\(alert)", withOkayButton: true, withCancelButton: false, okayHandler: nil, cancelHandler: nil)
                    }
                }
            }
        }
    }
}

// MARK: - WXApiDelegate
#if INCLUDE_WECHAT_OAUTH
extension AppDelegate: WXApiDelegate {
    func onReq(_ req: BaseReq!) {
        
    }
    
    func onResp(_ resp: BaseResp!) {
        let userInfo: [String: Any] = ["auth_resp": resp]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: AuraNotifications.WechatOAuthResponse), object: nil, userInfo: userInfo)
    }
}
#endif
