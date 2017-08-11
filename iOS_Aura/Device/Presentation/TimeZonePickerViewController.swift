//
//  TimeZonePickerViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

/// TimeZonePickerViewControllerDelegate

protocol TimeZonePickerViewControllerDelegate: class {
    func timeZonePickerDidCancel(_ picker: TimeZonePickerViewController)
    func timeZonePicker(_ picker: TimeZonePickerViewController, didSelectTimeZoneID timeZoneID:String)
}

// MARK: -

class TimeZonePickerViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {

    /// Delegate
    weak var delegate:TimeZonePickerViewControllerDelegate?

    /// Identifier (name) of the currently selected time zone
    var timeZoneID:String? {
        get {
            return self.privateTimeZoneID
        }
        set {
            self.privateTimeZoneID = newValue
            self.selectTimeZone(self.privateTimeZoneID)
        }
    }
    
    fileprivate var privateTimeZoneID:String? = nil
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    fileprivate let cellReuseIdentifier = "TimeZonePickerCell"
    fileprivate let timeZones = TimeZone.knownTimeZoneIdentifiers
    
    fileprivate enum TimeZonePickerViewControllerSection: Int {
        case timeZonePickerViewControllerSectionTimeZones = 0, timeZonePickerViewControllerSectionCount
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tintColor = UIColor.auraTintColor()
        self.tableView.allowsMultipleSelection = false;
        self.tableView.register(TimeZonePickerTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.selectTimeZone(self.timeZoneID)
    }
    
    // MARK: - Actions

    @IBAction fileprivate func cancel(_ sender: AnyObject) {
        self.delegate?.timeZonePickerDidCancel(self)
    }

    @IBAction fileprivate func save(_ sender: AnyObject) {
        if (self.timeZoneID != nil) {
            self.delegate?.timeZonePicker(self, didSelectTimeZoneID: self.timeZoneID!)
        } else {
            let alert = UIAlertController(title: "Please select a time zone", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction (title: "OK", style: UIAlertActionStyle.default, handler:nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Utilities
    
    fileprivate func selectTimeZone(_ timeZone: String?) {
        if (self.tableView == nil) {
            return;
        }
        
        // Deselect the current selection, if there is one
        if let currentSelectionIndexPath = self.tableView?.indexPathForSelectedRow {
            self.tableView.deselectRow(at: currentSelectionIndexPath, animated: true)
        }
        
        // Select the specificed timeZone, if provided and it exists
        if timeZone != nil {
            if let index = self.timeZones.index(of: timeZone!) {
                let indexPath = IndexPath.init(row: index, section: 0)
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            }
        }
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return TimeZonePickerViewControllerSection.timeZonePickerViewControllerSectionCount.rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows:Int = 0
        
        if let timeZonePickerSection = TimeZonePickerViewControllerSection(rawValue: section) {
            switch timeZonePickerSection {
                case .timeZonePickerViewControllerSectionTimeZones:
                    numRows = self.timeZones.count
                default:
                    assert(true, "Unexpected section!")
            }
        }
        
        return numRows
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as UITableViewCell
        
        cell.textLabel!.text = self.timeZones[indexPath.row]
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        var highlight = true
        
        // Don't highlight the selected cell
        if (indexPath == tableView.indexPathForSelectedRow) {
            highlight = false;
        }

        return highlight
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var pathToSelect:IndexPath? = nil
        
        // Don't allow additional selections of the currently selected cell
        if (indexPath != tableView.indexPathForSelectedRow) {
            pathToSelect = indexPath;
        }
        
        return pathToSelect
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let timeZonePickerSection = TimeZonePickerViewControllerSection(rawValue: indexPath.section) {
            switch timeZonePickerSection {
                case .timeZonePickerViewControllerSectionTimeZones:
                    self.privateTimeZoneID = self.timeZones[indexPath.row]
                break
                default:
                    assert(true, "Unexpected section!")
            }
        }
    }
}

// MARK: -

private class TimeZonePickerTableViewCell : UITableViewCell {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.default, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        // Update the background color to profide a visual affordance on touch down, but not have a highlight after touch up
        self.contentView.backgroundColor = highlighted ? UIColor.auraTintColor() : nil;
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.accessoryType = selected ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        self.textLabel?.textColor = selected ? UIColor.auraTintColor() : UIColor.black
    }
    
    func commonInit() {
        self.selectionStyle = UITableViewCellSelectionStyle.none
        self.textLabel?.backgroundColor = UIColor.clear
    }
}
