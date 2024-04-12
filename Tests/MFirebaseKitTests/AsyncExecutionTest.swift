//
//  AsyncExecutionTest.swift
//  
//
//  Created by Joschua Marz on 12.04.24.
//

import XCTest

final class AsyncExecutionTest: XCTestCase {

    class AsyncExecuter {
        let expectation: XCTestExpectation
        var didExecute: Bool = false
        
        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }
        
        func execute() {
            Task {
                didExecute = true
                expectation.fulfill()
            }
        }
    }
    
    func testAsyncExecution() async {
        let expectation = XCTestExpectation(description: "this")
        let sut = AsyncExecuter(expectation: expectation)
        sut.execute()
        await fulfillment(of: [expectation])
        XCTAssertTrue(sut.didExecute)
    }

}
