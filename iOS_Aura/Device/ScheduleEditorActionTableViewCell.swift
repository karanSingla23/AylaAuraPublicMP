//
//  ScheduleEditorActionTableViewCell.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit
import iOS_AylaSDK

class ScheduleEditorActionTableViewCell : UITableViewCell {
    
    @IBOutlet fileprivate weak var mainLabel: UILabel!
    @IBOutlet fileprivate weak var infoLabel: UILabel!
    @IBOutlet fileprivate weak var actionActiveLabel: UILabel!

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func mainLabelTextFromScheduleAction (_ action: AylaScheduleAction) -> String {
        let text = "Set " + action.name + " to " + String(describing: action.value as AnyObject)
        return text
    }
    
    fileprivate func infoLabelTextFromScheduleAction (_ action: AylaScheduleAction) -> String {
        var firepointString = ""
        switch action.firePoint{
        case .atEnd:
            firepointString = "At End of schedule"
        case .atStart:
            firepointString = "At Start of schedule"
        case .inRange:
            firepointString = "During schedule (In Range)"
        case .unspecified:
            firepointString = "At Unspecified point"
        }
        let text = "Fires " + firepointString
        return text
    }
    
    func configure(_ scheduleAction: AylaScheduleAction) {
        mainLabel.text = mainLabelTextFromScheduleAction(scheduleAction)
        infoLabel.text = infoLabelTextFromScheduleAction(scheduleAction)
        if scheduleAction.isActive {
            actionActiveLabel.text = "Active"
            actionActiveLabel.textColor = UIColor.auraLeafGreenColor()
        } else {
            actionActiveLabel.text = "Inactive"
            actionActiveLabel.textColor = UIColor.auraRedColor()
        }
    }
    
}
