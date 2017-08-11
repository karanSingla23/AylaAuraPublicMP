//
//  ScheduleEditorViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleEditorViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDataSource, UIPickerViewDelegate{
    private let logTag = "ScheduleEditorViewController"
    fileprivate var sessionManager : AylaSessionManager?
    
    fileprivate enum RepeatType: Int {
        case none
        case daily
        case weekends
        case weekdays
        static let count : Int = {
            var count = 0
            while let _ = RepeatType(rawValue: count) { count += 1 }
            return count
        }()
    }
    
    fileprivate var repeatType = RepeatType.none
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    @IBOutlet fileprivate weak var actionsTitleLabel: UILabel!
    @IBOutlet fileprivate weak var displayNameTextField: UITextField!
    @IBOutlet fileprivate weak var activeSwitch: UISwitch!
    @IBOutlet fileprivate weak var utcSwitch: UISwitch!
    
    @IBOutlet fileprivate weak var startDateTextField: UITextField!
    @IBOutlet fileprivate weak var startDatePicker: UIDatePicker!
    @IBOutlet fileprivate weak var startTimeTextField: UITextField!
    @IBOutlet fileprivate weak var startTimePicker: UIDatePicker!
    
    @IBOutlet fileprivate weak var endDateTextField: UITextField!
    @IBOutlet fileprivate weak var endDatePicker: UIDatePicker!
    @IBOutlet fileprivate weak var endTimeTextField: UITextField!
    @IBOutlet fileprivate weak var endTimePicker: UIDatePicker!
    
    @IBOutlet fileprivate weak var repeatTextField: UITextField!
    @IBOutlet fileprivate weak var repeatPicker: UIPickerView!
    @IBOutlet fileprivate weak var saveScheduleButton: AuraButton!
    
    @IBOutlet fileprivate weak var addActionButton: UIButton!
    @IBOutlet fileprivate weak var actionsTableView : UITableView!
    @IBOutlet fileprivate weak var actionsTableViewHeightConstraint: NSLayoutConstraint!
    
    fileprivate var dateFormatter : DateFormatter! = DateFormatter()
    fileprivate var timeFormatter : DateFormatter! = DateFormatter()
    fileprivate var timeZone : TimeZone! = TimeZone.autoupdatingCurrent
    fileprivate var actions : [AylaScheduleAction]?
    
    fileprivate static let NoActionCellId: String = "NoActionsCellId"
    fileprivate static let ActionDetailCellId: String = "ActionDetailCellId"
    
    fileprivate let segueToScheduleActionEditorId : String = "toScheduleActionEditor"
    
    fileprivate let actionCellHeight: Int = 65
    
    var schedule : AylaSchedule? = nil {
        didSet {
            if schedule?.isUsingUTC != nil {
                timeZone = schedule!.isUsingUTC ? TimeZone(secondsFromGMT: 0) : TimeZone.autoupdatingCurrent
            }
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = timeZone
            timeFormatter.dateFormat = "HH:mm:00"
            timeFormatter.timeZone = timeZone
        }
    }
    fileprivate var startDate : Date? = nil
    fileprivate var endDate : Date? = nil
    fileprivate var startTime : Date? = nil
    fileprivate var endTime : Date? = nil
    
    var device : AylaDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let sessionManager = AylaNetworks.shared().getSessionManager(withName: AuraSessionOneName) {
            self.sessionManager = sessionManager
        }
        else {
            AylaLogD(tag: logTag, flag: 0, message:"- WARNING - session manager can't be found")
        }
        
        displayNameTextField.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self
        startTimeTextField.delegate = self
        endTimeTextField.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        addActionButton.tintColor = UIColor.auraLeafGreenColor()
        
        endDateTextField.inputView = UIView()
        startDateTextField.inputView = UIView()
        endTimeTextField.inputView = UIView()
        startTimeTextField.inputView = UIView()
        
        actionsTableView.dataSource = self
        actionsTableView.delegate = self
        
        repeatTextField.delegate = self
        repeatTextField.inputView = UIView()
        repeatPicker.dataSource = self
        repeatPicker.delegate = self
        

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if schedule == nil {
            UIAlertController.alert("Internal Error", message: "Schedule is null.  This should not happen.", buttonTitle: "OK", fromController: self, okHandler: { (action) in
                self.cancel()
            })
        } else {
            // Fetch and refresh actions fresh every time page is displayed.
            fetchActions({
                AylaLogD(tag: self.self.logTag, flag: 0, message:"Fetched Actions.  Total count \(self.actions!.count)")
                if let table = self.actionsTableView {
                    table.reloadData()
                    self.autoResizeActionsTable()
                }
                }) { (error) in
                    UIAlertController.alert("Failed to fetch actions", message: error.description, buttonTitle: "OK", fromController: self)
            }
            populateUIFromSchedule()
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.autoResizeActionsTable()
    }
    
    fileprivate func autoResizeActionsTable(){
        // Called to adjust autolayout constraints of actions tableview to after adding or removing actions
        let baseHeight = actionCellHeight
        var height : CGFloat = CGFloat(baseHeight)
        if actions != nil {
            if !actions!.isEmpty {
                height = CGFloat(baseHeight * actions!.count)
            }
        }
        actionsTableViewHeightConstraint.constant = height
        view.layoutIfNeeded()
    }
    
    fileprivate func populateUIFromSchedule() {
        // Populate UI elements based on properties of associated schedule.
        if schedule != nil {
            if schedule?.fixedActions == true {
                addActionButton.isEnabled = false
                actionsTitleLabel.text = "Fixed Schedule Actions"
            }
            else {
                addActionButton.isEnabled = true
                actionsTitleLabel.text = "Schedule Actions"
            }
            
            startDate = schedule!.startDate != nil ? dateFormatter.date(from: schedule!.startDate!) : nil
            endDate = schedule!.endDate != nil ? dateFormatter.date(from: schedule!.endDate!) : nil
            
            startTime = schedule!.startTimeEachDay != nil ? timeFormatter.date(from: schedule!.startTimeEachDay!) : nil
            
            endTime = schedule!.endTimeEachDay != nil ? timeFormatter.date(from: schedule!.endTimeEachDay!) : nil
            
            startDatePicker.timeZone = timeZone
            endDatePicker.timeZone = timeZone
            startTimePicker.timeZone = timeZone
            endTimePicker.timeZone = timeZone
            
            startDatePicker.date = startDate ?? Date()
            endDatePicker.date = endDate ?? Date()
            startTimePicker.date = startTime ?? Date()
            endTimePicker.date = endTime ?? Date()
            
            setDateTextFieldValue(startDate, field:startDateTextField)
            setDateTextFieldValue(endDate, field:endDateTextField)
            setTimeTextFieldValue(startTime, field:startTimeTextField)
            setTimeTextFieldValue(endTime, field:endTimeTextField)

            utcSwitch.isOn = schedule!.isUsingUTC
            displayNameTextField.text = schedule!.displayName
            activeSwitch.isOn = schedule!.isActive
            
            repeatType = .none
            if let daysOfWeek = schedule!.daysOfWeek {
                let intAndNumberArraysAreEqual: ([Int],[NSNumber]) -> Bool = { (intArray, numberArray) in
                    var equals = true
                    for number in numberArray {
                        if !intArray.contains(number.intValue) {
                            equals = false
                            break
                        }
                    }
                    return equals
                }
                if intAndNumberArraysAreEqual([1,7],daysOfWeek) {
                    repeatType = .weekends
                } else if intAndNumberArraysAreEqual(Array(2...6),daysOfWeek) {
                    repeatType = .weekdays
                }
            } else if schedule!.endDate == nil || schedule!.endDate!.isEmpty {
                repeatType = .daily
            }
            self.repeatPicker.selectRow(repeatType.rawValue, inComponent: 0, animated: true)
            repeatTextField.text = "\(RepeatType(rawValue: repeatType.rawValue)!)"
        }
    }
    
    
    @objc fileprivate func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    @objc fileprivate func cancel() {
        let _ = navigationController?.popViewController(animated: true)
    }

    fileprivate func toggleViewVisibilityAnimated(_ view: UIView){
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.33, animations: {
                view.isHidden = !(view.isHidden)
            }) 
        }
    }

    fileprivate func setDateTextFieldValue(_ date: Date?, field: UITextField) {
        if date != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = timeZone
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .none
            field.text = dateFormatter.string(from: date!)
        } else {
            field.text = ""
        }
    }
    
    fileprivate func setTimeTextFieldValue(_ date: Date?, field: UITextField) {
        if date != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = timeZone
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .long
            field.text = dateFormatter.string(from: date!)
        } else {
            field.text = ""
        }
    }

    @IBAction fileprivate func utcSwitchTapped(_ sender: UISwitch) {
        timeZone = sender.isOn ? TimeZone(secondsFromGMT: 0) : TimeZone.autoupdatingCurrent

        dateFormatter.timeZone = timeZone
        timeFormatter.timeZone = timeZone
        
        startDatePicker.timeZone = timeZone
        endDatePicker.timeZone = timeZone
        startTimePicker.timeZone = timeZone
        endTimePicker.timeZone = timeZone
        
        setDateTextFieldValue(startDate, field: startDateTextField)
        setTimeTextFieldValue(startTimePicker.date, field: startTimeTextField)
        setDateTextFieldValue(endDate, field: endDateTextField)
        setTimeTextFieldValue(endTime, field: endTimeTextField)
    }
    
    @IBAction fileprivate func startDateFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(startDatePicker)
    }
    
    @IBAction fileprivate func startTimeFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(startTimePicker)
    }

    @IBAction fileprivate func endDateFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(endDatePicker)
    }
    
    @IBAction fileprivate func endTimeFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(endTimePicker)
    }
    
    @IBAction fileprivate func repeatFieldTapped(_ sender:AnyObject){
        toggleViewVisibilityAnimated(repeatPicker)
    }
    
    @IBAction fileprivate func startDatePickerChanged(_ sender: UIDatePicker) {
        startDate = sender.date
        setDateTextFieldValue(startDate!, field:startDateTextField)
    }

    @IBAction fileprivate func endDatePickerChanged(_ sender: UIDatePicker) {
        endDate = sender.date
        setDateTextFieldValue(endDate!, field:endDateTextField)
    }
    
    @IBAction fileprivate func startTimePickerChanged(_ sender: UIDatePicker) {
        startTime = sender.date
        setTimeTextFieldValue(startTime!, field:startTimeTextField)
    }
    
    @IBAction fileprivate func endTimePickerChanged(_ sender: UIDatePicker) {
        endTime = sender.date
        setTimeTextFieldValue(endTime!, field:endTimeTextField)
    }
    
    @IBAction fileprivate func addScheduleActionButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: segueToScheduleActionEditorId, sender: nil)
    }
    
    // MARK: Schedule Handling Methods
    
    fileprivate func fetchActions(_ success : @escaping ()-> Void, failure : @escaping (NSError)->Void) {
        if schedule == nil { return }
        schedule!.fetchAllScheduleActions(success: { (actions) in
            // Sort Actions to display AtStart first, then AtEnd, then InRange
            let sortedActions = actions.sorted(by: { $0.firePoint.rawValue < $1.firePoint.rawValue })
            self.actions = sortedActions
            success();
        }) { (error) in
            failure(error as NSError);
        }

    }

    fileprivate func clearAllActions() {
        if schedule == nil { return }
        let confirmationAlert = UIAlertController(title: "Delete Actions", message: "Are you sure you want to delete all actions associated with this schedule? This will not delete the schedule, just the actions.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.schedule?.deleteAllScheduleActions(success: {
                self.fetchActions({
                    self.populateUIFromSchedule()
                    UIAlertController.alert("Success", message: "Deleted all schedule actions", buttonTitle: "OK", fromController: self)
                    }, failure: { (error) in
                        UIAlertController.alert("Error", message: "Could not update action status\n\n\(error.description)", buttonTitle: "OK", fromController: self)
                        AylaLogD(tag: self.logTag, flag: 0, message:"Failed to update actions, status: \(error)")
                })
            }) { (error) in
                UIAlertController.alert("Error", message: "Could not delete actions\n\n\(error.description)", buttonTitle: "OK", fromController: self)
                AylaLogD(tag: self.logTag, flag: 0, message:"Failed to delete actions \(error)")
            }
        }
        confirmationAlert.addAction(confirmAction)
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(confirmationAlert, animated: true, completion: nil)
    }
    
    
    @IBAction fileprivate func saveScheduleButtonPressed(_ sender: AuraButton) {
        if schedule == nil { return }
        
        var startDateString : String? = nil
        var startTimeString : String? = nil
        var endDateString : String? = nil
        var endTimeString : String? = nil
        
        if startDate != nil {
            startDateString = dateFormatter.string(from: self.startDate!)
        }
        if startTime != nil {
            // remove seconds
            startTimeString = timeFormatter.string(from: self.startTime!)
        }
        if endDate != nil {
            endDateString = dateFormatter.string(from: self.endDate!)
        }
        if endTime != nil {
            // remove seconds
            endTimeString = timeFormatter.string(from: self.endTime!)
        }

        schedule!.displayName = displayNameTextField.text
        schedule!.startDate = startDateString
        schedule!.startTimeEachDay = startTimeString
        schedule!.endDate = endDateString
        schedule!.endTimeEachDay = endTimeString
        
        switch repeatType {
        case .weekdays:
            schedule!.daysOfWeek = Array(2...6).map { NSNumber(integerLiteral: $0) } // monday through friday
        case .weekends:
            schedule!.daysOfWeek = [1,7] //sunday and saturday
        case .daily:
            fallthrough
        case .none:
            schedule!.dayOccurOfMonth = nil
            schedule!.daysOfMonth = nil
            schedule!.daysOfWeek = nil
        }
        
        schedule!.isUsingUTC = utcSwitch.isOn
        saveScheduleButton.isEnabled = false
        schedule!.isActive = activeSwitch.isOn
        
        if let scheduleDevice = self.device {
            scheduleDevice.update(schedule!, success: { (schedule) -> Void in
                self.schedule = schedule
                UIAlertController.alert("Success", message: "Schedule Updated sucessfully", buttonTitle: "OK", fromController: self, okHandler: { (action) in
                self.cancel()
                })
                        }) { (error) -> Void in
                self.saveScheduleButton.isEnabled = true
                UIAlertController.alert("Error", message: "Failed to Save Schedule.\n\n\(error.description)", buttonTitle: "OK", fromController: self)
                AylaLogD(tag: self.logTag, flag: 0, message:"Failed to update schedule \(error)")
                }
        } else {

            UIAlertController.alert("Error", message: "Cannot find device", buttonTitle: "OK", fromController: self, okHandler: { (action) in
                self.cancel()
            })
        }
    }
    
    // MARK: Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if actions != nil {
            if actions!.isEmpty || actions!.count < 1 {
                return 1
            } else {
                return actions!.count
            }
        }
        else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if actions != nil {
            if !actions!.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ScheduleEditorViewController.ActionDetailCellId) as! ScheduleEditorActionTableViewCell
                cell.backgroundColor = UIColor.white
                cell.configure(self.actions![indexPath.row])
                return cell
            } else {
                let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: ScheduleEditorViewController.NoActionCellId)!
                cell.backgroundColor = UIColor.clear
                return cell
            }
        } else {
            let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: ScheduleEditorViewController.NoActionCellId)!
            cell.backgroundColor = UIColor.clear
            return cell
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(actionCellHeight)
    }
    
    
    // MARK: Table View Delegate    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if schedule == nil { return }

        if schedule!.fixedActions == true {
            UIAlertController.alert("Fixed Actions", message: "This schedule has fixed actions which cannot be edited.", buttonTitle: "OK", fromController: self)
        } else {
            if let actions = self.actions {
                if actions.count > 0 {
                    performSegue(withIdentifier: segueToScheduleActionEditorId, sender: actions[indexPath.row])
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only allow editing of rows for non-fixed actions
        if schedule?.fixedActions == true {
            return false
        }
        return actions != nil ? true : false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if schedule?.fixedActions == true {
            return []
        }
        if let actions = self.actions {
            let deleteActionAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
                let schedAction: AylaScheduleAction? = actions[indexPath.row]
                // Delete action
                _ = self.schedule?.delete(schedAction!, success: {
                    // Fetch fresh actions once deletion is finished
                    self.fetchActions({
                        tableView.reloadData()
                        self.autoResizeActionsTable()
                        }, failure: { (error) in
                            UIAlertController.alert("Failed to Refresh Actions", message: error.description, buttonTitle: "OK", fromController: self, okHandler: { (alertAction) in
                                tableView.reloadData()
                            })
                    })
                    
                    }, failure: { (error) in
                        UIAlertController.alert("Failed to Delete Action", message: error.description, buttonTitle: "OK", fromController: self)
                        tableView.reloadData()
                })
            }
            deleteActionAction.backgroundColor = UIColor.auraRedColor()
            return [deleteActionAction]
        }

        return []
    }
    
    
    // MARK: Text Field Delegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // Disallow certain text fields from being manually edited

        switch textField {
        case startDateTextField:
            toggleViewVisibilityAnimated(startDatePicker)
            return false
        case endDateTextField:
            toggleViewVisibilityAnimated(endDatePicker)
            return false
        case startTimeTextField:
            toggleViewVisibilityAnimated(startTimePicker)
            return false
        case endTimeTextField:
            toggleViewVisibilityAnimated(endTimePicker)
            return false
        case repeatTextField:
            toggleViewVisibilityAnimated(repeatPicker)
            return false
        default:
            return true
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        // Handle clearing of special text fields and their associated pickers and vars
        switch textField {
        case startDateTextField:
            startDatePicker.reloadInputViews()
            startDate = nil
            return true
        case endDateTextField:
            endDatePicker.reloadInputViews()
            endDate = nil
            return true
        case startTimeTextField:
            return false
        case endTimeTextField:
            endTimePicker.reloadInputViews()
            endTime = nil
            return true
        case repeatTextField:
            repeatPicker.reloadInputViews()
            return true
        default:
            return false
        }
    }
    
    
    // MARK: - UIPickerView Datasource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case repeatPicker:
            return RepeatType.count
        default:
            return 0
        }
    }
    
    
    // MARK: - UIPickerView Delegate

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case repeatPicker:
            repeatType = RepeatType(rawValue: row)!
            repeatTextField.text = "\(RepeatType(rawValue: row)!)"
        default:
            break
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case repeatPicker:
            return "\(RepeatType(rawValue: row)!)"
        default:
            return nil
        }
    }
    
    
    // MARK: - Navigation
        
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueToScheduleActionEditorId {
            let scheduleActionEditorController = segue.destination as! ScheduleActionEditorViewController
            scheduleActionEditorController.schedule = schedule
            if sender != nil {
                scheduleActionEditorController.action = (sender as! AylaScheduleAction)
            }
        }
    }
    
}
