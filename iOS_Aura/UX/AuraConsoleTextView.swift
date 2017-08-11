//
//  AuraConsoleTextView.swift
//  iOS_Aura
//
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import UIKit

class AuraConsoleTextView : UITextView {
    private let logTag = "AuraConsoleTextView"
    
    enum ConsoleLoggingLevel {
        case pass, fail, warning, error, info, debug
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.textColor = UIColor.darkText
        
        // Default background is light gray to contrast to default white vc background.
        self.backgroundColor = UIColor.groupTableViewBackground
    }
    
    fileprivate func tagFromLoggingLevel(_ level: ConsoleLoggingLevel) -> String {
        var tag :String
        switch level {
        case .pass:
            tag = "P"
            break
        case .fail:
            tag = "F"
            break
        case .error:
            tag = "E"
            break
        case .warning:
            tag = "W"
            break
        case .info:
            tag = "I"
            break
        case .debug:
            tag = "D"
            break
        }
        
        return tag
    }
    
    fileprivate func attributedStringFromLoggingLevel(_ level: ConsoleLoggingLevel, logText: String) -> NSAttributedString? {
        
        var htmlString :String = "\(tagFromLoggingLevel(level)), \(logText)"
        let fontSettings = "face=\"-apple-system\",\"HelveticaNeue\""
        switch level {
        case .pass:
            htmlString = "<font \(fontSettings) color=\"LimeGreen\">\(htmlString)</font>"
            break
        case .fail:
            htmlString = "<font \(fontSettings) color=\"Red\">\(htmlString)</font>"
            break
        case .error:
            htmlString = "<font \(fontSettings) color=\"DarkBlue\">\(htmlString)</font>"
            break
        case .warning:
            htmlString = "<font \(fontSettings) color=\"Blue\">\(htmlString)</font>"
            break
        case .info:
            htmlString = "<font \(fontSettings)>\(htmlString)</font>"
            break
        case .debug:
            htmlString = "<font \(fontSettings)>\(htmlString)</font>"
            break
        }
        
        let data = htmlString.data(using: String.Encoding.utf8)!
        let attributedOptions = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]
        var string :NSAttributedString?
        do {
            string = try NSAttributedString(data: data, options: attributedOptions, documentAttributes: nil)
        } catch _ {
            AylaLogD(tag: logTag, flag: 0, message:"Cannot create attributed String")
        }
        
        return string
    }
    
    /**
     Call this method to add a tagged log message to the console.
     Scrolls to bottom when done.
     - parameter level: Logging level of this message.
     - parameter log:   Log text.
     */
    func addLogLine(_ level: ConsoleLoggingLevel, log: String) {
        if let attributedLogText = attributedStringFromLoggingLevel(level, logText: log) {
            self.addAttributedLogline(attributedLogText)
        }
        else  {
            self.addLogLine("\(tagFromLoggingLevel(level)), \(log)")
        }
    }
    
    /**
     Use this method to add a new line to the console. Scrolls to bottom when done.
     */
    func addLogLine(_ untaggedLog: String) {
        self.addAttributedLogline(NSAttributedString(string: untaggedLog))
    }
    
    /**
     Use this method to append an attributed string on text view.
     */
    func addAttributedLogline(_ attributedText :NSAttributedString) {
        let wholeText =  self.attributedText.mutableCopy() as! NSMutableAttributedString
        wholeText.append(NSAttributedString(string: "\n"))
        wholeText.append(attributedText)
        self.attributedText = wholeText
        // This scrolls the view to the bottom when the text extends beyond the edges
        let count = self.text.characters.count
        let bottom = NSMakeRange(count, 0)
        self.scrollRangeToVisible(bottom)
        
    }
    
    func clear() {
        self.attributedText = NSMutableAttributedString()
    }
}

