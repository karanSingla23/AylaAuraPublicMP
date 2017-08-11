//
//  NetworkProfilerModel.swift
//  iOS_Aura
//
//  Created by Emanuel Peña Aguilar on 10/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import UIKit
import iOS_AylaSDK
import QuartzCore
import AFNetworking

class NetworkProfilerModel: TestModel, AylaLanTaskProfilerListener, AylaCloudTaskProfilerListener {
    var device :AylaDevice!
    var networkDuration : CFTimeInterval = 0
    
    init(testPanelVC: TestPanelViewController, device: AylaDevice?) {
        super.init(testPanelVC: testPanelVC)
        
        self.device = device
        AylaProfiler.sharedInstance().addListener(self)
    }
    
    var totalTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
    var networkTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
    
    func didStartLANTask(_ task: AylaConnectTask!) {
        
    }
    
    func didFailLANTask(_ task: AylaConnectTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    
    func didSucceedLANTask(_ task: AylaConnectTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    
    func didStart(_ task: URLSessionDataTask!) {
        
    }
    
    func didFail(_ task: URLSessionDataTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    
    func didSucceed(_ task: URLSessionDataTask!, duration: CFTimeInterval) {
        networkDuration = duration
    }
    override func testPanelIsReady() {
        testPanelVC?.title = "Network Profiler"
        testPanelVC?.tf1.isHidden = false
        testPanelVC?.tf1Label.isHidden = false
        testPanelVC?.tf1Label.text = "Iters"
        testPanelVC?.tf1.keyboardType = .numberPad
        
        testPanelVC?.tf2.isHidden = false
        testPanelVC?.tf2Label.isHidden = false
        testPanelVC?.tf2Label.text = "LAN Mode"
        testPanelVC?.tf2.keyboardType = .numberPad
        testPanelVC?.tf2.isEnabled = false
        testPanelVC?.tf2.text = (device != nil && device!.isLanModeActive() ? "Enabled" : "Unavailable")
        
        testPanelVC?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearConsole))
        
    }
    
    func clearConsole() {
        testPanelVC?.consoleView.clear()
        totalTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
        networkTimes = ( lan:  Array<CFTimeInterval>(), cloud : Array<CFTimeInterval>())
    }
    
    func testTurnBlueLEDOnViaCloud(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.info, log: "Turning blue LED on via Cloud")
        let startTime = CACurrentMediaTime()
        _ = blueLEDProperty?.createDatapointCloud(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.cloud.append(totalTime)
            self.networkTimes.cloud.append(self.networkDuration)
            self.addLog(.info, log: self.timeResultsDescription("Cloud", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func timeResultsDescription(_ operationType:String, totalTime:CFTimeInterval, networkTime:CFTimeInterval) -> String {
        return "\(operationType) Operation Total: \(String(format: "%.0f",totalTime*1000))ms, Network Total: \(String(format: "%.0f",networkTime*1000))ms, \(String(format: "%.2f%%",networkTime/totalTime*100))"
    }
    
    func testTurnBlueLEDOffViaCloud(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.info, log: "Turning blue LED off via Cloud")
        let startTime = CACurrentMediaTime()
        _ = blueLEDProperty?.createDatapointCloud(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.cloud.append(totalTime)
            self.networkTimes.cloud.append(self.networkDuration)
            self.addLog(.info, log: self.timeResultsDescription("Cloud", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func testTurnBlueLEDOnViaLAN(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.info, log: "Turning blue LED on via LAN")
        let startTime = CACurrentMediaTime()
        _ = blueLEDProperty?.createDatapointLAN(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.lan.append(totalTime)
            self.networkTimes.lan.append(self.networkDuration)
            self.addLog(.info, log: self.timeResultsDescription("LAN", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    func testTurnBlueLEDOffViaLAN(_ tc: TestCase)  {
        addLog(.info, log: "Start \(#function)")
        let blueLEDProperty = device?.getProperty("Blue_LED")
        let turnOffDatapoint = AylaDatapointParams ()
        turnOffDatapoint.value = 0
        
        addLog(.info, log: "Turning blue LED off via LAN")
        let startTime = CACurrentMediaTime()
        _ = blueLEDProperty?.createDatapointLAN(turnOffDatapoint, success: { (createdDatapoint) in
            
            let endTime = CACurrentMediaTime();
            let totalTime = endTime-startTime
            self.totalTimes.lan.append(totalTime)
            self.networkTimes.lan.append(self.networkDuration)
            self.addLog(.info, log: self.timeResultsDescription("LAN", totalTime: totalTime, networkTime: self.networkDuration))
            
            self.passTestCase(tc)
            }, failure: { (error) in
                self.failTestCase(tc, error: error)
        })
    }
    
    override func start() -> Bool {
        if (super.start()) {
            setupTestSequencer()
            
            var iters = 1
            if let text = self.testPanelVC?.tf1.text {
                if let input = Int(text) {
                    iters = input > 0 ? input : 1
                }
            }
            
            self.testPanelVC?.iterCountLabel.text = "1/\(iters)"
            testSequencer?.start(UInt(iters))
            return true
        }
        
        return false
    }
    
    override func setupTestSequencer() {
        let sequencer = TestSequencer()
            .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOnViaCloud)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOffViaCloud(testCase) })
            .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOffViaCloud)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOffViaCloud(testCase) })
        if device.isLanModeActive() {
            _ = sequencer
                .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOnViaLAN)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOnViaLAN(testCase) })
                .addTest(NSStringFromSelector(#selector(testTurnBlueLEDOffViaLAN)), testBlock: { [weak self] (testCase) in self?.testTurnBlueLEDOffViaLAN(testCase) })
        }
        
        testSequencer = sequencer
    }
    override func finishedOnTestSequencer(_ testSequencer: TestSequencer) {
        super.finishedOnTestSequencer(testSequencer)
        addLog(.info, log: "Results: \(timeResultsDescription("Cloud", totalTime: totalTimes.cloud.reduce(0,{ $0 + $1 }), networkTime: networkTimes.cloud.reduce(0,{ $0 + $1 })))")
        addLog(.info, log: "Average Results: \(timeResultsDescription("Cloud", totalTime: totalTimes.cloud.reduce(0,{ $0 + $1 })/Double(self.totalTimes.cloud.count), networkTime: networkTimes.cloud.reduce(0,{ $0 + $1 })/Double(self.networkTimes.cloud.count)))")
        
        
        addLog(.info, log: "Results: \(timeResultsDescription("LAN", totalTime: totalTimes.lan.reduce(0,{ $0 + $1 }), networkTime: networkTimes.lan.reduce(0,{ $0 + $1 })))")
        addLog(.info, log: "Average Results: \(timeResultsDescription("LAN", totalTime: totalTimes.lan.reduce(0,{ $0 + $1 })/Double(self.totalTimes.lan.count), networkTime: networkTimes.lan.reduce(0,{ $0 + $1 })/Double(self.networkTimes.lan.count)))")
    }
}
