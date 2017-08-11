//
//  GuidedSetupWiFiSelection.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 4/18/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import UIKit

class  GuidedSetupWiFiSelection: UITableViewController {
    var model :GuidedSetupModel!
    var setupNavigationController : GuidedSetupNavigationController? {
        get {
            return self.navigationController as? GuidedSetupNavigationController
        }
    }
    
    struct Constants {
        struct CellIdentifiers {
            static let basicCell = "BasicCell"
            static let discoveredNetworkCell = "DiscoveredNetworkCell"
        }
        
        enum Segue :String {
            case ssidAuthentication = "SSIDAuthenticationSegue"
        }
        
        struct Strings {
            static let cellLabelOther = "Other..."
            static let headerDiscoveredNetworks = "DISCOVERED NETWORKS"
            static let headerSavedNetworks = "SAVED NETWORKS"
        }
        
        enum Section :Int {
            case savedNetworks = -1 // disabled, make 0 to enable
            case discoveredNetworks = 0
            case hiddenNetwork
            
            static var count : Int {
                get {
                    return 2
                }
            }
            
            var cellIdentifier :String {
                get {
                    switch self {
                    case .discoveredNetworks:
                        return CellIdentifiers.discoveredNetworkCell
                    case .hiddenNetwork:
                        return CellIdentifiers.basicCell
                    case .savedNetworks:
                        return CellIdentifiers.basicCell
                    }
                    
                }
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.model.cancel()
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.model.wiFiScanResults == nil {
            fetchWiFiList()
        }
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(fetchWiFiList), for: .valueChanged)
    }
    
    @IBAction func fetchWiFiList() {
        self.setupNavigationController?.displayProgressView(animated: true, completion: { 
            
            self.model.fetchDeviceAccessPoints({
                self.tableView.reloadData()
                self.setupNavigationController?.hideProgressView(animated: true)
                
                self.refreshControl?.endRefreshing()
            }, failure: { (error) in
                
                self.refreshControl?.endRefreshing()
                self.setupNavigationController?.hideProgressView(animated: true, completion: {
                    UIAlertController.alert("Error fetching WiFi list", message: String(describing: error), buttonTitle: "OK", fromController: self)
                })
            })
        })
        self.setupNavigationController?.modalProgress.textLabel.text = "Connected to \nDSN: \(self.model.setup.setupDevice?.dsn ?? "Unknown DSN")\n\nDiscovering nearby networks"
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.Section.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Constants.Section(rawValue: section) else {
            return 0
        }
        switch section {
        case .discoveredNetworks:
            guard let scanResults = model.wiFiScanResults else {
                return 0
            }
            return scanResults.results.count
        case .hiddenNetwork:
            return 1
        case .savedNetworks:
            return 1 //TODO replace with actual count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Constants.Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: section.cellIdentifier)!
        switch section {
        case .discoveredNetworks:
            guard let wiFiResult = self.model.wiFiScanResults?.results[indexPath.row] else {
                return UITableViewCell()
            }
            (cell as? DiscoveredNetworkTableViewCell)?.configure(withWiFiResult: wiFiResult)
        case .savedNetworks:
            cell.textLabel?.text = "TBD: implement saved WiFi"
        case .hiddenNetwork:
            cell.textLabel?.text = Constants.Strings.cellLabelOther
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Constants.Section(rawValue: section) else {
            return nil
        }
        switch section {
        case .discoveredNetworks:
            return Constants.Strings.headerDiscoveredNetworks
        case .savedNetworks:
            return Constants.Strings.headerSavedNetworks
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Constants.Section(rawValue: indexPath.section) else {
            return
        }
        switch section {
        case .discoveredNetworks:
            guard let scanResult = model.wiFiScanResults?.results[indexPath.row] else {
                return
            }
            self.model.ssidName = scanResult.ssid
            self.model.ssidSecurity = scanResult.security
            performSegue(withIdentifier: Constants.Segue.ssidAuthentication.rawValue, sender: nil)
        case .savedNetworks:
            return //TODO replace with actual count
        case .hiddenNetwork:
            self.model.ssidSecurity = "hidden"
            performSegue(withIdentifier: Constants.Segue.ssidAuthentication.rawValue, sender: nil)
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier, let _segue = Constants.Segue(rawValue: segueId) else {
            return
        }
        switch _segue {
        case .ssidAuthentication:
            guard let wiFiAuthentication = segue.destination as? GuidedSetupEnterPasswordTableViewController else {
                return
            }
            wiFiAuthentication.model = model
        }
    }
}
