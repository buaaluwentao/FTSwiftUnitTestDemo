//
//  FTTransectionTest.swift
//  FTSwiftUnitTestDemoTests
//
//  Created by wentao lu on 2021/12/2.
//

import XCTest

class FTTransectionTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testExecute_normal_returnTrue() {
        let transection = FTTransection(preAssignedId: nil,
                                        id: "transection",
                                        buyerId: 1001,
                                        sellerId: 2001,
                                        productId: 3001,
                                        orderId: "transection_order_id",
                                        amount: 100)
        let transectionLock = FTTransectionLock()
        let service = FTWallerRpcService.init()
        transection.setLock(lock: transectionLock)
        transection.setService(service: service)
        
        XCTAssertTrue(transection.executed())
    }
    
    func testExecute_expired_returnFalse() {
        class FTTestTransection: FTTransection {
            override func expired() -> Bool {
                true
            }
        }
        
        let transection = FTTestTransection(preAssignedId: nil,
                                        id: "transection",
                                        buyerId: 1001,
                                        sellerId: 2001,
                                        productId: 3001,
                                        orderId: "transection_order_id",
                                        amount: 100)
        let transectionLock = FTTransectionLock()
        let service = FTWallerRpcService.init()
        transection.setLock(lock: transectionLock)
        transection.setService(service: service)
        
        XCTAssertFalse(transection.executed())
    }
}
