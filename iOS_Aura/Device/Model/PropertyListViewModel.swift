//
//  PropertyListViewModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 2/22/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

protocol PropertyListViewModelDelegate: class {
    func propertyListViewModel(_ viewModel:PropertyListViewModel, didSelectProperty property:AylaProperty, assignedPropertyModel propertyModel:PropertyModel)
    func propertyListViewModel(_ viewModel:PropertyListViewModel, displayPropertyDetails property:AylaProperty, assignedPropertyModel propertyModel:PropertyModel)
}

class PropertyListViewModel: NSObject, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, AylaDeviceListener {
    
    /// Default property cell id
    static let PropertyCellId: String = "PropertyCellId"
    /// Expanded property cell id
    static let ExpandedPropertyCellId: String = "ExpandedPropertyCellId"
    
    /// Device
    let device: AylaDevice
    
    /// Delegate of property list view model
    weak var delegate: PropertyListViewModelDelegate?
    
    /// Table view of properties
    var tableView: UITableView
    
    /// Table view search bar
    let searchController:UISearchController?
    
    /// Properties which are being represented in table view.
    var properties : [ AylaProperty ]
    
    required init(device: AylaDevice, tableView: UITableView) {
        
        self.device = device
        self.properties = []
        
        self.tableView = tableView
        self.searchController = UISearchController(searchResultsController: nil)
        
        super.init()
        
        // Add self as device listener
        device.add(self)
        
        // Set search controller
        self.searchController?.searchResultsUpdater = self
        loadLastSearches()
        self.searchController?.hidesNavigationBarDuringPresentation = false
        self.searchController?.dimsBackgroundDuringPresentation = false
        self.searchController?.searchBar.delegate = self
        
        // Add search bar to table view
        self.searchController?.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchController?.searchBar
        
        // Set a content offset to hide search bar.
        let barHeight = self.searchController?.searchBar.frame.size.height ?? 0
        self.tableView.contentOffset = CGPoint(x: 0, y: barHeight)
        
        tableView.delegate = self
        tableView.dataSource = self
        self.updatePropertyListFromDevice()
    }
    
    func loadLastSearches() {
        let lastSearchContainer = UIToolbar(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
        lastSearchContainer.barTintColor = UIColor.auraTintColor()
        
        lastSearchContainer.items = lastSearches.map({ UIBarButtonItem(title: $0, style: .plain, target: self, action: #selector(applyLastSearch(pressedButton:))) })
        self.searchController?.searchBar.inputAccessoryView = lastSearchContainer
    }
    
    var lastSearches: [String] {
        get {
            return UserDefaults.standard.array(forKey: "LastPropertySearches") as? [String] ?? [String]()
        }
        set {
            let lastSearches = Array(newValue.prefix(5))
            UserDefaults.standard.set(lastSearches, forKey: "LastPropertySearches")
        }
    }
    
    func applyLastSearch(pressedButton: UITabBarItem) {
        searchController?.searchBar.text = pressedButton.title
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        var lastSearches = self.lastSearches
        lastSearches.insert(searchText, at: 0)
        self.lastSearches = lastSearches
        self.loadLastSearches()
    }
    
     /**
     Use this method to reload property list from device.
     
     - parameter searchText: User input search text, when set as nil, this api will only call tableview.reloadData()
     */
    func updatePropertyListFromDevice() {
        
        if let knownProperties = self.device.properties {
            // Only refresh properties list when there is a user search or property list is still empty.
            let search = searchController?.searchBar.text
            if search != nil || self.properties.count == 0 || self.properties.count != knownProperties.count {
                self.properties = knownProperties.values.map({ (property) -> AylaProperty in
                    return property as! AylaProperty
                }).filter({ (property) -> Bool in
                    return search ?? "" != "" ? property.name.lowercased().contains(search!.lowercased()) : true
                }).sorted(by: { (prop1, prop2) -> Bool in
                    // Do a sort to the property list based on property names.
                    return prop1.name < prop2.name
                })
            }
        }
        else {
            // No properties list found in device
            self.properties = []
        }
        
        tableView.reloadData()
    }
    
    /**
     A tap gesture recognizer uses this method to show an alert for modifying property values/creating datapoints.
     
     - parameter sender: UITapGestureRecognizer
     - parameter property: the AylaProperty to create datapoints for
     */
    func showValueAlertForProperty(_ sender: UITapGestureRecognizer, property: AylaProperty){
        self.delegate?.propertyListViewModel(self, didSelectProperty: property, assignedPropertyModel: PropertyModel(property: property, presentingViewController: nil))
    }
    
    /**
     A tap gesture recognizer uses this method to segue to a Property Details page.
     
     - parameter sender: UITapGestureRecognizer
     - parameter property: the AylaProperty to create datapoints for
     */
    func showDetailsForProperty(_ sender: UITapGestureRecognizer, property: AylaProperty){
        self.delegate?.propertyListViewModel(self, displayPropertyDetails: property, assignedPropertyModel: PropertyModel(property: property, presentingViewController: nil))
    }
    
    // MARK: Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.properties.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellId = PropertyListViewModel.ExpandedPropertyCellId
        let item = self.properties[indexPath.row] as AylaProperty
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? PropertyTVCell
        
        if (cell != nil) {
            cell?.configure(item)
        }
        else {
            assert(false, "\(cellId) - reusable cell can't be dequeued'")
        }
        cell?.parentPropertyListViewModel = self
        return cell!
    }
    
    // MARK: Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    // MARK - search controller

    func updateSearchResults(for searchController: UISearchController) {
       self.updatePropertyListFromDevice()
    }
    
    // MARK - device listener
    
    func device(_ device: AylaDevice, didFail error: Error) {
        // We do nothing to handle device errors here.
    }
    
    func device(_ device: AylaDevice, didObserve change: AylaChange) {
        // Not a smart way to update.
        if(change.isKind(of: AylaPropertyChange.self)) {
            AylaLogD(tag: logTag, flag: 0, message:"Obverse changes: \(change)")
            self.updatePropertyListFromDevice()
        }
    }
    
    private let logTag = "PropertyListViewModel"
}
