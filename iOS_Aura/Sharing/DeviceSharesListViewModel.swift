//
//  DeviceSharesListViewModel.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/5/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK

protocol DeviceSharesListViewModelDelegate: class {
    func deviceSharesListViewModel(_ viewModel:DeviceSharesListViewModel, didDeleteShare share:AylaShare)
    func deviceSharesListViewModel(_ viewModel:DeviceSharesListViewModel, didSelectShare share:AylaShare)

}

class DeviceSharesListViewModel:NSObject, UITableViewDataSource, UITableViewDelegate, AylaDeviceManagerListener, AylaDeviceListener {
    private let logTag = "DeviceSharsListViewModel"
    /// Device manager where device list belongs
    let deviceManager: AylaDeviceManager
    
    /// Table view of devices
    var tableView: UITableView?
    
    var sharesModel: DeviceSharesModel?
    
    var expandedRow: IndexPath?
    
    static let DeviceShareCellId: String = "DeviceShareCellId"
    
    enum SharesTableSection: Int {
        case ownedShares = 0
        case receivedShares
    }
    
    weak var delegate: DeviceSharesListViewModelDelegate?

    
    required init(deviceManager: AylaDeviceManager, tableView: UITableView) {
        
        self.deviceManager = deviceManager
        
        self.tableView = tableView
        
        self.sharesModel = DeviceSharesModel(deviceManager: self.deviceManager)
        super.init()
        
        self.sharesModel!.updateSharesList({ (shares) in
            self.tableView?.reloadData()
            }) { (error) in
        }
        // Add self as device manager listener
        deviceManager.add(self)
        
        // Add self as delegate and datasource of input table view.
        tableView.dataSource = self
        tableView.delegate = self
        
        self.sharesModel!.refreshDeviceList()
    }
    
    // MARK: Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SharesTableSection.ownedShares.rawValue{
            return self.sharesModel!.ownedShares.count
        } else if section == SharesTableSection.receivedShares.rawValue {
            return self.sharesModel!.receivedShares.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SharesTableSection.ownedShares.rawValue{
            return "Devices You Own"
        } else if section == SharesTableSection.receivedShares.rawValue {
            return "Devices Shared to You"
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var share: AylaShare?
        if indexPath.section == SharesTableSection.ownedShares.rawValue {
            share = self.sharesModel!.ownedShares[indexPath.row]
        } else if indexPath.section == SharesTableSection.receivedShares.rawValue {
            share = self.sharesModel!.receivedShares[indexPath.row]
        } else {
            assert(false, "Share for section \(indexPath.section), row \(indexPath.row) does not exist")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceSharesListViewModel.DeviceShareCellId) as? DeviceShareTVCell
        
        if (cell != nil) {
            let expand : Bool
            if let row = self.expandedRow {
                expand = row == indexPath ? true : false
            } else {
                expand = false
            }
            let device = self.sharesModel!.deviceForShare(share!)
            cell!.configure(share!, device: device, expanded:expand)
        }
        else {
            assert(false, "\(DeviceSharesListViewModel.DeviceShareCellId) - reusable cell can't be dequeued'")
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cellPath = self.expandedRow {
            if cellPath == indexPath{
                return DeviceShareTVCell.expandedRowHeight
            }
        }
        return DeviceShareTVCell.collapsedRowHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView.numberOfRows(inSection: section) == 0 {
            return tableView.statusHeaderFooterView("None", withActivityIndicator:false)
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let height : CGFloat = 54.0
        let zeroHeight : CGFloat = 0.0001
        if tableView.dataSource?.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return height
        }
        return zeroHeight
    }

    
    
    // MARK: Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var share: AylaShare?
        if indexPath.section == SharesTableSection.ownedShares.rawValue {
            share = self.sharesModel!.ownedShares[indexPath.row]
        } else if indexPath.section == SharesTableSection.receivedShares.rawValue {
            share = self.sharesModel!.receivedShares[indexPath.row]
        } else {
            assert(false, "Share for section \(indexPath.section), row \(indexPath.row) does not exist")
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        var rowsToReload : [IndexPath]
        if self.expandedRow == nil {
            self.expandedRow = indexPath
            rowsToReload = [self.expandedRow!]
        } else if self.expandedRow == indexPath {
            self.expandedRow = nil
            rowsToReload = [indexPath]
        } else {
            rowsToReload = [self.expandedRow!, indexPath]
            self.expandedRow = indexPath
        }
        
        tableView.reloadRows(at: rowsToReload, with: UITableViewRowAnimation.fade)
        self.delegate?.deviceSharesListViewModel(self, didSelectShare: share!)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let unshareAction = UITableViewRowAction(style: .default, title: "Unshare") { (action, indexPath) in
            var share: AylaShare?
            if indexPath.section == SharesTableSection.ownedShares.rawValue {
                share = self.sharesModel!.ownedShares[indexPath.row]
            } else if indexPath.section == SharesTableSection.receivedShares.rawValue {
                share = self.sharesModel!.receivedShares[indexPath.row]
            }
            self.delegate?.deviceSharesListViewModel(self, didDeleteShare: share!)
            self.expandedRow = nil
            tableView.reloadData()
        }
        unshareAction.backgroundColor = UIColor.auraRedColor()
        return [unshareAction]
    }
    
    
    // MARK - Device Manager Listener
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitComplete deviceFailures: [String : Error]) {
        AylaLogI(tag: logTag, flag: 0, message:"Init complete")
        self.sharesModel!.updateSharesList({ (shares) in
            self.tableView?.reloadData()
        }) { (error) in }
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didInitFailure error: Error) {
        AylaLogE(tag: logTag, flag: 0, message:"Failed to init: \(error)")
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, didObserve change: AylaDeviceListChange) {
        AylaLogI(tag: logTag, flag: 0, message:"Observe device list change")
        if change.addedItems.count > 0 {
            for device:AylaDevice in change.addedItems {
                device.add(self)
            }
        }
        else {
            // We don't remove self as listener from device manager removed devices.
        }
        
        self.sharesModel!.updateSharesList({ (shares) in
            self.tableView?.reloadData()
        }) { (error) in }
    }
    
    func deviceManager(_ deviceManager: AylaDeviceManager, deviceManagerStateChanged oldState: AylaDeviceManagerState, newState: AylaDeviceManagerState){
        
    }
    
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
        if change.isKind(of: AylaDeviceChange.self) || change.isKind(of: AylaDeviceListChange.self) {
            // Not a good long term update strategy
            
            self.sharesModel!.updateSharesList({ (shares) in
                self.tableView?.reloadData()
            }) { (error) in }
        }
        
    }
    
    func device(_ device: AylaDevice, didFail error: Error) {
        // Device errors are not currently handled here.
    }
}
