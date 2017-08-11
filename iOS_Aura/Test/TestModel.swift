//
//  TestModel.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 4/8/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation
import iOS_AylaSDK


enum TestModelTestState: String {
    case Empty = ""
    case Failure = "Failure"
    case Success = "Success"
    case Working = "Working"
}

/**
A TestModel represents a complete functional/integration test flow. It interacts with TestPanelViewController to receive user's actions and input, deploys tests, 
 and displays log messages in the on-screen console.
 When implementing a new test flow, you should always create a new subclass of TestModel, and override methods to input your own test flow.
 
 Some methods you could consider to override:
  - testPanelIsReady() A method which would be invoked from method viewDidLoad() of TestPanelViewController
  - testPanelIsDismissed() A method which would be invoked from method cancel() of TestPanelViewController
  - start() -> Bool Entry point of test cycle, all subclass of TestModel must override this method. Return true if test could be started.
  - stop() -> Bool Stop request sent from user, all subclass of TestModel must override this method. Return false if test could be stopped.
  - setupTestSequencer() Set this method to setup TestSequencer instance of this test model. Note this method is not called in TestModel class.
  - finishedOnTestSequencer() Notify all test cases in test sequencer have been completed. Make sure super.finishedOnTestSequencer() is called when you override it.
 */
class TestModel : NSObject, TestPanelVCDelegate {
    
    /// Reference to the view controller using this model.
    weak var testPanelVC : TestPanelViewController?
    
    var testSequencer :TestSequencer? {
        willSet(newSequencer) {
            if let old = testSequencer {
                old.stop()
            }
            newSequencer?.completeBlock = { [weak self] (sequencer) in self?.finishedOnTestSequencer(sequencer)}
            newSequencer?.progressBlock = { [weak self] (sequencer, _, total, completed) in
                return (self?.trackIterationProgress(sequencer, total: total, completed: completed)) ?? true
            }
        }
    
    }
    
    init(testPanelVC: TestPanelViewController) {
        self.testPanelVC = testPanelVC;
        super.init()
    }
    
    func testPanelIsReady() {
    }

    func testPanelIsDismissed() {
    }
    
    func start() -> Bool {
        self.testPanelVC?.errCountLabel.text = "0"
        self.testPanelVC?.iterCountLabel.text = "0/0"
        return true
    }
    
    func stop() -> Bool {
        return true
    }
    
    func finishedOnTestSequencer(_ testSequencer : TestSequencer) {
        if self.testSequencer == testSequencer {
            self.testPanelVC?.statusTF.text = testSequencer.errCount == 0 ? TestModelTestState.Success.rawValue : TestModelTestState.Failure.rawValue
            self.testPanelVC?.resetStartButton()
        }
    }
    
    func trackIterationProgress(_ testSequencer : TestSequencer, total: UInt, completed: UInt) -> Bool{
        if self.testSequencer == testSequencer {
            let showComplete = completed == total ? total : completed+1
            self.testPanelVC?.iterCountLabel.text = "\(showComplete)/\(total)"
        }
        return true
    }
    
    func setupTestSequencer() {
    }
    
    /**
     Call this method when input test case is passed.
     - parameter tc: Test case which is passed.
     */
    func passTestCase(_ tc: TestCase) {
        addLog(.pass, log: tc.description)
        tc.pass()
    }
    
    /**
     Call this method when input test case is failed.
     - parameter tc:    Test case which is passed.
     - parameter error: Generated error.
     */
    func failTestCase(_ tc: TestCase, error: Error?) {
        if let errText = self.testPanelVC?.errCountLabel.text {
            let errCount = Int(errText) ?? 0
            self.testPanelVC?.errCountLabel.text = "\(errCount+1)"
        }
        
        addLog(.fail, log: "\(tc.description) err: \(error?.description ?? "nil")")
        tc.fail()
    }
    
    /**
     Call this method to add a log message on text view of test panel.
     - parameter level: Logging level of this message.
     - parameter log:   Log text.
     */
    func addLog(_ level: AuraConsoleTextView.ConsoleLoggingLevel, log: String) {
        testPanelVC?.consoleView.addLogLine(level, log: log)
    }
    /*
    private func tagFromLoggingLevel(level: TestModelLoggingLevel) -> String {
        var tag :String
        switch level {
        case .Pass:
            tag = "P"
            break
        case .Fail:
            tag = "F"
            break
        case .Error:
            tag = "E"
            break
        case .Warning:
            tag = "W"
            break
        case .Info:
            tag = "I"
            break
        }
        return tag
    }
    */
    
    /*private func attributedStringFromLoggingLevel(level: AuraConsoleTextView.ConsoleLoggingLevel, logText: String) -> NSAttributedString? {
        var htmlString :String = "\(tagFromLoggingLevel(level)), \(logText)"
        let fontSettings = "face=\"-apple-system\",\"HelveticaNeue\""
        switch level {
        case .Pass:
            htmlString = "<font \(fontSettings) color=\"LimeGreen\">\(htmlString)</font>"
            break
        case .Fail:
            htmlString = "<font \(fontSettings) color=\"Red\">\(htmlString)</font>"
            break
        case .Error:
            htmlString = "<font \(fontSettings) color=\"DarkBlue\">\(htmlString)</font>"
            break
        case .Warning:
            htmlString = "<font \(fontSettings) color=\"Blue\">\(htmlString)</font>"
            break
        case .Info:
            htmlString = "<font \(fontSettings)>\(htmlString)</font>"
            break
        }
        
        let data = htmlString.dataUsingEncoding(NSUTF8StringEncoding)!
        let attributedOptions = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]
        var string :NSAttributedString?
        do {
            string = try NSAttributedString(data: data, options: attributedOptions, documentAttributes: nil)
        } catch _ {
            AylaLogD(tag: logTag, flag: 0, message:"Cannot create attributed String")
        }
        
        return string
    }*/
    
    // MARK: Test panel delegate
    func testPanelVC(_ viewController: TestPanelViewController, didTapOnStartButton startButton: UIButton) -> Bool {
    return start()
    }
    
    func testPanelVC(_ viewController: TestPanelViewController, didTapOnStopButton stopButton: UIButton) -> Bool {
    return stop()
    }
    
    func testPanelVC(_ viewController: TestPanelViewController, didTapOnButton1 button1: UIButton) -> Bool {
    return false
    }
    
    func testPanelVC(_ viewController: TestPanelViewController, didTapOnButton2 button2: UIButton) -> Bool {
    return false
    }
    
    func testPanelVC(_ viewController: TestPanelViewController, didTapOnButton3 button1: UIButton) -> Bool {
    return false
    }
    
}
