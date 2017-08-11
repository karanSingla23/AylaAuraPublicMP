//
//  NotificationsViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK
import UIKit

class NotificationsViewController: UIViewController, PropertyNotificationDetailsViewControllerDelegate {
    private let logTag = "NotificationViewController"
    var device: AylaDevice!
    
    var propertyTriggers = [AylaPropertyTrigger]()

    @IBOutlet fileprivate weak var tableView: UITableView!
    
    fileprivate enum NotificationsViewControllerSection: Int {
        case notificationsViewControllerSectionPropertyNotifications = 0, notificationsViewControllerSectionCount
    }

    fileprivate let propertyNotificationCellReuseIdentifier = "PropertyNotificationCell"

    /// Segue id to property notification details view
    fileprivate let segueIdToPropertyNotificationDetails: String = "toPropertyNotificationDetails"

    override func viewDidLoad() {
        super.viewDidLoad()

        self.reloadTriggers()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdToPropertyNotificationDetails {
            let nvc = segue.destination as! UINavigationController
            let vc = nvc.viewControllers[0] as! PropertyNotificationDetailsViewController
            vc.device = device
            vc.propertyTrigger = sender as? AylaPropertyTrigger
            vc.delegate = self
        }
    }

    // MARK: - Actions
    
    @IBAction fileprivate func addNotification(_ sender: AnyObject) {
        self.performSegue(withIdentifier: segueIdToPropertyNotificationDetails, sender: nil)
    }

    // MARK: - Utilities
    
    func reloadTriggers() {
        let fetchTriggersGroup = DispatchGroup()
        var fetchedPropertyTriggers = [AylaPropertyTrigger]()
        var fetchErrors = [Error]()
        
        // Rebuild the array by getting the properties we care about and fetching all triggers attached to them
        if let properties = device.managedPropertyNames() {
            for propertyName in properties {
                if let property = device.getProperty(propertyName) {
                    fetchTriggersGroup.enter()
                    property.fetchTriggers(success: { (triggers) in
                        fetchedPropertyTriggers += triggers
                        fetchTriggersGroup.leave()
                    }) { (error) in
                        fetchErrors.append(error)
                        fetchTriggersGroup.leave()
                    }
                }
            }
        }
        
        fetchTriggersGroup.notify(queue: DispatchQueue.main) {
            if !fetchErrors.isEmpty {
                AylaLogE(tag: self.logTag, flag: 0, message:"Failed to fetch \(fetchErrors.count) Property Triggers: \(fetchErrors)")
                UIAlertController.alert("Failed to fetch \(fetchErrors.count) Property Triggers", message: "First error: \(fetchErrors.first?.description ?? "nil")", buttonTitle: "OK", fromController: self)
            }
            
            // Now that all of the fetch requests have completed, update our table with the new data
            self.propertyTriggers = fetchedPropertyTriggers
            self.tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return NotificationsViewControllerSection.notificationsViewControllerSectionCount.rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows:Int = 0
        
        if let notificationsSection = NotificationsViewControllerSection(rawValue: section) {
            switch notificationsSection {
            case .notificationsViewControllerSectionPropertyNotifications:
                numRows = self.propertyTriggers.count
            default:
                assert(false, "Unexpected section!")
            }
        }
        
        return numRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if let notificationsSection = NotificationsViewControllerSection(rawValue: indexPath.section) {
            switch notificationsSection {
            case .notificationsViewControllerSectionPropertyNotifications:
                cell = tableView.dequeueReusableCell(withIdentifier: propertyNotificationCellReuseIdentifier, for: indexPath) as UITableViewCell
                cell.accessoryType = .disclosureIndicator
                
                let trigger = propertyTriggers[indexPath.row]
                
                cell.textLabel?.text = trigger.deviceNickname
                
                var triggerDescription = ""
                switch trigger.triggerType {
                case .always:
                    triggerDescription = "trigger on a new datapoint"
                case .compareAbsolute:
                    let compareTypeName = AylaPropertyTrigger.comparisonName(fromType: trigger.compareType)
                    triggerDescription = "when value \(compareTypeName) \(trigger.value)"
                case .onChange:
                    triggerDescription = "when a different value is set"
                case .unknown:
                    triggerDescription = "unknown trigger type"
                }

                let triggerTypeName = AylaPropertyTrigger.triggerTypeName(from: trigger.triggerType)
                cell.detailTextLabel?.text = "\(trigger.propertyNickname) \(triggerTypeName) \(triggerDescription)"

            default:
                assert(false, "Unexpected section!")
            }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if let notificationsSection = NotificationsViewControllerSection(rawValue: indexPath.section) {
            switch notificationsSection {
            case .notificationsViewControllerSectionPropertyNotifications:
                self.performSegue(withIdentifier: segueIdToPropertyNotificationDetails, sender: propertyTriggers[indexPath.row])
            default:
                assert(false, "Unexpected section!")
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [UITableViewRowAction]? {
        var actions: [UITableViewRowAction] = []
        
        if let notificationsSection = NotificationsViewControllerSection(rawValue: indexPath.section) {
            switch notificationsSection {
            case .notificationsViewControllerSectionPropertyNotifications:
                let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (rowAction, indexPath) in
                    let trigger = self.propertyTriggers[indexPath.row]
                    
                    let _ = trigger.property?.delete(trigger, success: {
                        if let index = self.propertyTriggers.index(of: trigger) {
                            self.propertyTriggers.remove(at: index)
                        } else {
                            assert(false, "failed to get the index of the trigger that was just deleted which should never happen!")
                        }
                        
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        }, failure: { (error) in
                            UIAlertController.alert("Failed to delete trigger", message: error.description, buttonTitle: "OK", fromController: self)
                    })
                }

                actions.append(deleteAction)
            default:
                assert(false, "Unexpected section!")
            }
        }
        
        return actions
    }
    
    // MARK: - PropertyNotificationDetailsViewControllerDelegate
    
    func propertyNotificationDetailsDidCancel(_ controller: PropertyNotificationDetailsViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func propertyNotificationDetailsDidSave(_ controller: PropertyNotificationDetailsViewController){
        reloadTriggers()
        self.dismiss(animated: true, completion: nil)
    }
}
