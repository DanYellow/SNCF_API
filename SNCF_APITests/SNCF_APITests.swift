//
//  SNCF_APITests.swift
//  SNCF_APITests
//
//  Created by Jean-Louis Danielo on 07/01/2016.
//  Copyright © 2016 Jean-Louis Danielo. All rights reserved.
//

import XCTest
@testable import SNCF_API

class SNCF_APITests: XCTestCase {
    

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testToast() {
        let foo = 10;
        
        XCTAssertEqual(foo, 10);
    }
    
}
