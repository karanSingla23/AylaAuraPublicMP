//
//  AuraSessionListener.swift
//  iOS_Aura
//
//  Created by Kavita Khanna on 8/31/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class AuraSessionListener : NSObject, AylaSessionManagerListener {
    
    static let sharedListener = AuraSessionListener()
    
    // Current device manager
    var sessionManager : AylaSessionManager?
    
    func initializeAuraSessionListener() {
        
        self.sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
        self.sessionManager?.add(self)
    }
    
    deinit {
        
        // Remove yourself from session listener list
        if let sessionMgr = self.sessionManager {
            sessionMgr.remove(self)
        }
    }

    func sessionManager(_ sessionManager: AylaSessionManager, didRefreshAuthorization authorization: AylaAuthorization) {
        // Do nothing
    }

    func sessionManager(_ sessionManager: AylaSessionManager, didCloseSession error: Error?) {
        
        // On session close event, just remove the session listener
        if let sessionMgr = self.sessionManager {
            sessionMgr.remove(self)
        }
        
        // If no error, user signed out. No need to re-login.
        guard (error != nil) else {
            return
        }
    
        // On session close event (if due to error), go to login page to restart the app flow.
        // This method is invoked if auth token refresh fails, in which case,
        // any other call to cloud service would fail.
        guard (Thread.isMainThread) else {
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).displayLoginView()
            }
            return
        }
        
        (UIApplication.shared.delegate as! AppDelegate).displayLoginView()

    }
}
