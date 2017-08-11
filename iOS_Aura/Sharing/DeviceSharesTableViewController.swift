//
//  DeviceSharesTableViewController.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 5/3/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class DeviceSharesTableViewController: UITableViewController, DeviceSharesModelDelegate, DeviceSharesListViewModelDelegate {
    private let logTag = "DeviceSharesTableViewController"
    /// The current session manager which retains the device manager.
    var sessionManager :AylaSessionManager?
    
    /// View model used by view controller to present device shares list.
    var viewModel : DeviceSharesListViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName)
        
        if (sessionManager != nil) {
            viewModel = DeviceSharesListViewModel(deviceManager: sessionManager!.deviceManager, tableView: tableView)
            viewModel?.delegate = self
            self.viewModel?.sharesModel?.delegate = self

        }
        else {
            AylaLogW(tag: logTag, flag: 0, message:"device list with a nil session manager")
            // TODO: present a warning and give fresh option
        }
        
        
        self.navigationController?.navigationBar.isTranslucent = false;
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh shares")
        self.refreshControl?.addTarget(self, action: #selector(DeviceSharesTableViewController.refreshShareData), for: .valueChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cancel() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func reloadTableData(){
        self.tableView.reloadData()
    }
    
    func refreshShareData(){
        AylaLogI(tag: logTag, flag: 0, message:"Manually Refreshing Share Data.")
        self.viewModel!.sharesModel!.updateSharesList({ (shares) in
            self.reloadTableData()
            self.refreshControl?.endRefreshing()
        }) { (error) in
            self.refreshControl?.endRefreshing()
            UIAlertController.alert("Failed to Refresh", message: error.description, buttonTitle: "OK", fromController: self)
        }
    }
    
    // MARK: - DeviceSharesListViewModelDelegate
    func deviceSharesListViewModel(_ viewModel:DeviceSharesListViewModel, didDeleteShare share:AylaShare) {
        let model = ShareViewModel(share: share)
        model.deleteShare(self, successHandler: {
            self.viewModel!.sharesModel?.updateSharesList({ (shares) in
                    self.reloadTableData()
                }, failureHandler: { (error) in
                    let alert = UIAlertController(title: "Failed to Update Shares List.", message: error.description, preferredStyle: .alert)
                    let gotIt = UIAlertAction(title: "Got it", style: .cancel, handler: nil)
                    alert.addAction(gotIt)
                    self.present(alert, animated: true, completion: nil)
                    self.reloadTableData()
            })
            }) { (error) in }
    }
    func deviceSharesListViewModel(_ viewModel:DeviceSharesListViewModel, didSelectShare share:AylaShare) {

    }
    
    // MARK: DeviceSharesModelDelegate
    func deviceSharesModel(_ model: DeviceSharesModel, ownedSharesListDidUpdate: ((_ shares: [AylaShare]) -> Void)?) {
        self.reloadTableData()
    }
    func deviceSharesModel(_ model: DeviceSharesModel, receivedSharesListDidUpdate: ((_ shares: [AylaShare]) -> Void)?) {
        self.reloadTableData()
    }
    
}
