//
//  UITableView+AuraStatus.swift
//  iOS_Aura
//
//  Created by Kevin Bella on 6/8/17.
//  Copyright © 2017 Ayla Networks. All rights reserved.
//

import Foundation

extension UITableView {

    func statusHeaderFooterView(_ labelString:String, withActivityIndicator:Bool) -> UIView {
        let view = UIView(frame: CGRect.zero)
        let label = UILabel()
        label.text = labelString
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 18.0)
        label.textColor = UIColor.lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        if withActivityIndicator {
            let activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            activityIndicator.isUserInteractionEnabled = false;
            activityIndicator.startAnimating()
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(activityIndicator)
            
            NSLayoutConstraint(
                item: label,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: activityIndicator,
                attribute: .leading,
                multiplier: 1.0,
                constant: 8.0
                ).isActive = true
            
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 22.0
                ).isActive = true
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 22.0
                ).isActive = true
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .centerY,
                relatedBy: .equal,
                toItem: view,
                attribute: .centerY,
                multiplier: 1.0,
                constant: 0.0
                ).isActive = true
            NSLayoutConstraint(
                item: activityIndicator,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: view,
                attribute: .trailing,
                multiplier: 1.0,
                constant: -16.0
                ).isActive = true
        } else {
            NSLayoutConstraint(
                item: label,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: view,
                attribute: .trailing,
                multiplier: 1.0,
                constant: 8.0
                ).isActive = true
            
        }
        
        NSLayoutConstraint(
            item: label,
            attribute: .top,
            relatedBy: .equal,
            toItem: view,
            attribute: .top,
            multiplier: 1.0,
            constant: 0.0
            ).isActive = true
        
        NSLayoutConstraint(
            item: label,
            attribute: .leading,
            relatedBy: .equal,
            toItem: view,
            attribute: .leading,
            multiplier: 1.0,
            constant: 36.0
            ).isActive = true
        NSLayoutConstraint(
            item: label,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: view,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 8.0
            ).isActive = true
        
        return view
    }

}

// Supporting code needed for statusHeaderFooterView to be fully useful
/*
override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    if tableView.numberOfRows(inSection: section) == 0 {
        return tableView.statusHeaderFooterView("None", withActivityIndicator:false)
    }
    return nil
}
 
 override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
 let height : CGFloat = 40.0
 let zeroHeight : CGFloat = 0.0001
 if tableView.dataSource?.tableView(tableView, numberOfRowsInSection: section) == 0 ||
 (section == Section.name.rawValue) {
 return height
 }
 return zeroHeight
 }
 
 */
