//
//  ScheduleTableViewController.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK

class ScheduleTableViewController: UITableViewController {
    fileprivate let segueToScheduleEditorId = "toScheduleEditor"
    fileprivate let scheduleCellID = "ScheduleTableViewCell"
    
    var device : AylaDevice!
    fileprivate var schedules = [AylaSchedule]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        refreshControl?.isEnabled = true
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh schedules")
        refreshControl?.addTarget(self, action: #selector(reloadSchedules), for: .valueChanged)    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSchedules()
    }
    
    @objc fileprivate func reloadSchedules() {
        // fetch schedules
        device.fetchAllSchedules(success: { (schedules) in
            //assign schedules in case of success
            self.schedules = schedules
            
            //reload table view
            self.tableView.reloadData()
            if self.refreshControl?.isRefreshing == true {
                self.refreshControl?.endRefreshing()
            }
        }) { (error) in
            if self.refreshControl?.isRefreshing == true {
                self.refreshControl?.endRefreshing()
            }
            // display an alert in case of error
            UIAlertController.alert("Failed to fetch schedules", message: error.localizedDescription, buttonTitle: "OK", fromController: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.schedules.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: scheduleCellID, for: indexPath) as! ScheduleTableViewCell
        let schedule = schedules[indexPath.row]
        cell.configure(schedule)
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let schedule = schedules[indexPath.row]
        performSegue(withIdentifier: segueToScheduleEditorId, sender: schedule)
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == segueToScheduleEditorId) {
            let schedule : AylaSchedule = (sender as? AylaSchedule)!
            let scheduleEditorController = segue.destination as! ScheduleEditorViewController
            scheduleEditorController.device = device
            scheduleEditorController.schedule = schedule
        }
    }

}
