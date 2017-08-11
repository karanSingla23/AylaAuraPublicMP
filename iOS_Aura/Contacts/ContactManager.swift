//
//  ContactManager.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK

class ContactManager {
    static let sharedInstance = ContactManager()
    
    private let logTag = "ContactManager"
    
    fileprivate(set) var contacts: [AylaContact]?

    fileprivate var sessionManager: AylaSessionManager?
    
    fileprivate init() {

    }
    
    func reload() {
        sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
        contacts = nil
        fetchContacts()
    }
    
    func contactWithID(_ contactID: NSNumber) -> AylaContact? {
        if let index = contacts?.index(where: {$0.id == contactID}) {
            return contacts![index]
        }
        
        return nil
    }

    fileprivate func fetchContacts() {
        _ = sessionManager?.fetchContacts({ (contacts: [AylaContact]) in
            self.contacts = contacts
            }, failure: { (error) in
                AylaLogW(tag: self.logTag, flag: 0, message:"Failed to fetch contacts! (\(error))")
        })
    }
}
