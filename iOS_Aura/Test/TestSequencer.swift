//
//  TestSequencer.swift
//  iOS_Aura
//
//  Created by Yipei Wang on 4/10/16.
//  Copyright © 2016 Ayla Networks. All rights reserved.
//

import Foundation

typealias CompleteBlock = (TestSequencer) -> Void
typealias ProgressBlock = (_ testSequencer :TestSequencer, _ completedTestCaseInCurretnIteration:[TestCase], _ totalInterations:UInt, _ completedIterations: UInt) -> Bool

/*
 A TestSequencer manages a list of TestCases, it counts error when going through all error cases and call completeBlock when all test cases have been finished.
 */
class TestSequencer : NSObject {
    
    // MARK - Settings
    
    /// If test should continue when one of test case was failed.
    var continueAfterFailure :Bool = true
    
    var totalIterations :UInt = 1
    var completedIterations :UInt = 0
    
    // MARK - Attributes
    
    fileprivate(set) var nextTestIndex :Int = 0
    fileprivate(set) var testSuite :Array<TestCase> = []
    
    fileprivate(set) var errCount :Int = 0
    
    fileprivate(set) var STARTED :Bool = false
    fileprivate(set) var FINISHED :Bool = false
    fileprivate(set) var STOPPED :Bool = false

    var completeBlock :CompleteBlock?
    var progressBlock :ProgressBlock?
    
    func addTest(_ description :String, testBlock :@escaping TestBlock) -> TestSequencer {
        let test = TestCase(description: description, testBlock: testBlock)
        test.sequencer = self
        testSuite.append(test)
        return self
    }
    
    func addTestCase(_ testCase :TestCase) -> TestSequencer {
        testCase.sequencer = self
        testSuite.append(testCase)
        return self
    }
    
    func start(_ iterations: UInt) {
        STARTED = true
        self.totalIterations = iterations
        if testSuite.count > 0 {
            // Reset index
            nextTestIndex = 0
            
            let testCase = testSuite[0]
            testCase.start()
        }
        else  {
            FINISHED = true
        }
    }
    
    func stop() {
        STOPPED = true
        FINISHED = true
    }

    internal func finish() {
        FINISHED = true
        if let completeBlock = self.completeBlock {
            completeBlock(self)
        }
    }
    
    func finishedTestCase(_ testCase :TestCase) {
        if testCase.FAILED {
            errCount += 1
        }
        
        if !STOPPED {
            if testCase.FAILED && !continueAfterFailure {
                finish()
            }
            else {
                nextTestIndex += 1
                if nextTestIndex < testSuite.count {
                    let testCase = testSuite[nextTestIndex]
                    testCase.start()
                }
                else {
                    completedIterations += 1;
                    if let progressBlock = progressBlock {
                        let _ = progressBlock(self, self.testSuite,
                                      totalIterations,
                                      completedIterations)
                    }
                    
                    if totalIterations == completedIterations {
                        // Completed all iterations
                        finish()
                    }
                    else {
                        resetTestSuiteWithKnownTestCases()
                        
                        // Reset index1
                        nextTestIndex = 0
                        
                        let testCase = testSuite[0]
                        testCase.start()
                    }
                }
            }
        }
        else {
            finish()
        }
    }
    
    func resetTestSuiteWithKnownTestCases() {
    
        var newTestSuite :[TestCase] = []
        for curTest in testSuite {
            let testCase = TestCase(description: curTest.description, testBlock: curTest.testBlock)
            testCase.sequencer = self
            newTestSuite.append(testCase)
        }
        
        testSuite = newTestSuite
    }
    
}
