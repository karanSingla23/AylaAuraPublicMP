//
//  ScheduleTableViewCell.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleTableViewCell : UITableViewCell {
    
    
    @IBOutlet fileprivate weak var mainLabel: UILabel!
    @IBOutlet fileprivate weak var infoLabelTop: UILabel!
    @IBOutlet fileprivate weak var infoLabelBottom: UILabel!
    @IBOutlet fileprivate weak var actionActiveLabel: UILabel!
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    func configure(_ schedule: AylaSchedule) {
        self.mainLabel.text = "\(schedule.displayName ?? "") (\(schedule.name))"
        
        let startTimeEachDay = "\(schedule.startTimeEachDay ?? "")"
        let endTimeEachDay = "\(schedule.endTimeEachDay ?? "No end time")"
        
        let startDate = "\(schedule.startDate ?? "Immediately")"
        let endDate = "\(schedule.endDate ?? "indefinite")"
        let utc = "\(schedule.isUsingUTC ? "UTC" : "Non-UTC (Local)")"
        
        
        self.infoLabelTop?.text = "Start \(startDate) - \(startTimeEachDay), \(utc)"
        
        self.infoLabelBottom?.text = "End \(endDate) - \(endTimeEachDay), \(utc)"

        if schedule.isActive {
            actionActiveLabel.text = "Active"
            actionActiveLabel.textColor = UIColor.auraLeafGreenColor()
        } else {
            actionActiveLabel.text = "Inactive"
            actionActiveLabel.textColor = UIColor.auraRedColor()
        }
    }
    
}
