//
//  PropertyModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 3/11/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import iOS_AylaSDK

protocol PropertyModelDelegate: class {
    func propertyModel(_ model:PropertyModel, didSelectAction action:PropertyModelAction)
}

public enum PropertyModelAction : Int {
    case details // details
}

class PropertyModel: NSObject, UITextFieldDelegate {
    private let logTag = "PropertyModel"
    /// Property presented by this model
    var property: AylaProperty
    
    /// Delegate of current property model
    weak var delegate :PropertyModelDelegate?
    
    required init(property:AylaProperty, presentingViewController: UIViewController?) {
        self.property = property
        super.init()
    }
    
    /**
     Use this method to present an UIAlertController with defined options:
     1) Update with input value
     2) Cancel
     
     - parameter viewController: The view controller which presents this action controller.
     */
    func presentActions(presentingViewController viewController: UIViewController){
        
        // Don't update file property by inputing text
        if property.baseType == "file" {
            return
        }
    
        let alertController = UIAlertController(title: property.name, message: nil, preferredStyle: .alert)

        let updateAction = UIAlertAction(title: "Update Value", style: .default) { (_) in
            let textField = alertController.textFields![0] as UITextField
            let dpParams = AylaDatapointParams()
            if let val = self.valueFromString(textField.text!) {
                dpParams.value = val
                self.property.createDatapoint(dpParams, success: { (datapoint) -> Void in
                    AylaLogD(tag: self.logTag, flag: 0, message:"Created datapoint.")
                    }, failure: { (error) -> Void in
                        error.displayAsAlertController()
                })
            }
        }
        updateAction.isEnabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
            NotificationCenter.default.removeObserver(alertController.textFields![0])
            alertController.textFields![0].resignFirstResponder()
        }
        
        alertController.addTextField { (textField) in

            textField.placeholder = "baseType: \(self.property.baseType)"
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                if self.valueFromString(textField.text) != nil {
                    updateAction.isEnabled = true
                }
                else {
                    updateAction.isEnabled = false
                }
            }
        }
        alertController.addAction(updateAction)
        alertController.addAction(cancelAction)
        
        viewController.present(alertController, animated: true, completion: { () -> Void in
            
        })
    }
    
    /**
     A method that forwards a PropertyModelAction to the PropertyModel delegate
     
     - parameter action: A PropertyModelAction sent to the delegate
    */
    func chosenAction(_ action: PropertyModelAction){
        self.delegate?.propertyModel(self, didSelectAction: action)
    }
    
    /**
     A helpful method to validate and transfer input string value
     
     - parameter str: The value in string
     
     - returns: Value in right type. Returns nil if input value is invalid.
     */
    func valueFromString(_ str:String?) -> AnyObject? {
    
        if str == nil {
            return nil;
        }
        else if self.property.baseType == "string" || self.property.baseType == "file" {
            return str as AnyObject?;
        }
        else if self.property.baseType == "integer" {
            if let intValue = Int(str!) {
                return NSNumber(value: intValue as Int)
            }
        }
        else if self.property.baseType == "boolean" {
            if str == "1" { return NSNumber(value: 1 as Int32) }
            if str == "0" { return NSNumber(value: 0 as Int32) }
            return nil
        }
        else {
            if let doubleValue = Double(str!) {
                return NSNumber(value: doubleValue as Double)
            }
        }
        
        return nil
    }
    
    func previewAction(presentingViewController viewController: UIViewController) {
        if property.datapoint is AylaDatapointBlob {
            let blob = property.datapoint as! AylaDatapointBlob
            let fileName = (blob.value as! NSString).lastPathComponent
            // delete the `.json` suffix
            let filePath = NSURL(fileURLWithPath: "\(cachePath()!)/\(fileName)").deletingPathExtension!
            
            if FileManager.default.fileExists(atPath: filePath.path) {
                preview(filePath, presentingViewController: viewController)
                return
            }
            
            let alertController = UIAlertController(title: nil, message: "Please wait...\n\n", preferredStyle: UIAlertControllerStyle.alert)
            let spinnerIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = UIColor.black
            spinnerIndicator.startAnimating()
            alertController.view.addSubview(spinnerIndicator)
            
            let task = blob.download(toFile: filePath,
                progress: { (progress) in
                    DispatchQueue.main.async(execute: { 
                        alertController.message = "Please wait...\(progress.localizedDescription)\n\n"
                    })
                },
                success: { (url) in
                    alertController.dismiss(animated: false, completion: nil)
                    
                    self.preview(url, presentingViewController: viewController)
                },
                failure: { (error) in
                    spinnerIndicator.removeFromSuperview()
                    alertController.message = error.localizedDescription
                    AylaLogD(tag: self.logTag, flag: 0, message:"Error: \(error)")
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                task.cancel()
            })
            alertController.addAction(cancelAction)
            viewController.present(alertController, animated: false, completion: nil)
        }
        else {
            AylaLogD(tag: self.logTag, flag: 0, message:"preview is only for file property")
        }
    }
    
    func cachePath() -> String? {
        if let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            var isDir: ObjCBool = false
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: cachePath, isDirectory: &isDir) == false && !isDir.boolValue {
                try! fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: false, attributes: nil)
            }
            return cachePath
        }
        
        return nil
    }
    
    func preview(_ fileURL: URL, presentingViewController viewController: UIViewController) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        viewController.present(activityController, animated: true, completion: nil)
    }
}
