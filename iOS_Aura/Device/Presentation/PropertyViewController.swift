//
//  PropertyViewController.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 3/13/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class PropertyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var baseTypeLabel: UILabel!
    @IBOutlet weak var previewButton: AuraButton!
    @IBOutlet weak var tableView: UITableView!
    
    var propertyModel: PropertyModel?
    var datapoints = [AylaDatapoint]()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        refresh()
    }
    
    /**
     Use this method to refresh UI
     */
    func refresh() {
        if let property = propertyModel?.property {
            displayNameLabel.text = property.displayName
            valueLabel.text = "\(String.stringFromStringNumberOrNil(property.value as AnyObject?))"
            nameLabel.text = property.name
            baseTypeLabel.text = property.baseType
            if property.baseType != "file" {
                previewButton.removeFromSuperview()
            }
        }
    }
    
    @IBAction func prviewAction(_ sender: AnyObject) {
        propertyModel?.previewAction(presentingViewController: self)
    }
    
    @IBAction func fetchDatapoints() {
        propertyModel?.property.fetchDatapoints(withCount: 10, from: nil, to: nil, success: { (datapoints) in
            self.datapoints = datapoints
            self.tableView.reloadData()
        }) { (error) in
            AylaLogE(tag: self.logTag, flag: 0, message: "Error fetching datapoint history: \(error)")
        }
    }
    
    var logTag: String {
        get {
            return "PropertyViewController"
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datapoints.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "cell"
        var cell : UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        
        let datapoint = datapoints[indexPath.row]
        
        cell.textLabel?.text = String.stringFromStringNumberOrNil(datapoint.value as AnyObject)
        if let createdAt = datapoint.createdAt {
            cell.detailTextLabel?.text = "@ \(createdAt)"
        } else {
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
}
