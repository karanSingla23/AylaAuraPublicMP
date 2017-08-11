//
//  TestCase.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 4/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation

typealias TestBlock = (TestCase) -> Void

/**
 A TestCase represents an unit in test flow.
 */
class TestCase : NSObject {

    var testBlock: TestBlock
    var description_: String?
    override var description: String {
        return description_ ?? ""
    }
    
    weak var sequencer: TestSequencer?

    fileprivate(set) var PASSED :Bool = false
    fileprivate(set) var FAILED :Bool = false
    fileprivate(set) var FINISHED : Bool = false
    
    init(description: String?, testBlock: @escaping TestBlock) {
        self.testBlock = testBlock
        self.description_ = description
    }
    
    func pass() {
        FINISHED = true;
        PASSED = true;
        sequencer?.finishedTestCase(self)
    }
    
    func fail() {
        FINISHED = true;
        FAILED = true;
        sequencer?.finishedTestCase(self)
    }
    
    func start() {
        if !FINISHED {
            testBlock(self)
        }
    }
    
    
}
