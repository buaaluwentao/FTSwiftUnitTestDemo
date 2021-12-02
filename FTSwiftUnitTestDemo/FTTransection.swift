//
//  FTTransection.swift
//  FTSwiftUnitTestDemo
//
//  Created by wentao lu on 2021/12/2.
//

import Foundation
import UIKit

enum FTTransectionStatus {
    case ToBeExecuted, Expired, Executed, Fail
}

class FTIDGenerator {
    static func generateId() -> String {
        return "\(Date().timeIntervalSince1970)"
    }
}

//单例
class FTDistributedLock {
    static private let instance: FTDistributedLock = FTDistributedLock()
    static func share() -> FTDistributedLock {
        return instance
    }
    
    func lockTransectionId(_ id: String) -> Bool {
        return true
    }
    
    func unlockTransectionId(_ id: String) {
 
    }
}

class FTWallerRpcService {
    func moveMoney(id: String, buyerId: Int, sellerid: Int) -> String? {
        return "\(Date().timeIntervalSince1970)"
    }
}

class Transection {
    private var id: String
    private let buyerId: Int?
    private let sellerId: Int?
    private let productId: Int
    private let orderId: String
    private var createTimeStamp: TimeInterval
    private var amount: Double
    private var status: FTTransectionStatus
    private var walletTransectionId: String?
    
    init(preAssignedId: String?,
         id: String,
         buyerId: Int?,
         sellerId: Int?,
         productId: Int,
         orderId: String,
         status: FTTransectionStatus) {
        //1. 属性创建代码过多，导致代码不干净
        if let preAssignedId = preAssignedId, !preAssignedId.isEmpty {
            self.id = preAssignedId
        } else {
            self.id = FTIDGenerator.generateId()
        }
        
        if !self.id.starts(with: "t_") {
            self.id = "t_" + (preAssignedId ?? "0")
        }
        
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.productId = productId
        self.orderId = orderId
        self.createTimeStamp = Date().timeIntervalSince1970
        self.amount = 0
        self.status = .ToBeExecuted
    }
    
    func executed() -> Bool {
        if (buyerId == nil) ||
            (sellerId == nil) ||
            (amount < 0) {
            return false
        }
        
        if status == .Executed { return true }
        
        //2. 单例对象
        let isLocked = FTDistributedLock.share().lockTransectionId(id)
        if !isLocked { return false }
        
        if status == .Executed { return true }
        
        //3. 未决状态
        if Date().timeIntervalSince1970 - createTimeStamp > 14 * 24 * 3600 {
            return false
        }
        
        //4. 非依赖注入的对象
        let rpcService = FTWallerRpcService()
        let walletTransectionId = rpcService.moveMoney(id: id, buyerId: buyerId!, sellerid: sellerId!)
        self.walletTransectionId = walletTransectionId
        status = (walletTransectionId != nil) ? .Executed : .Fail
        
        if isLocked { FTDistributedLock.share().unlockTransectionId(id) }
        return status == .Executed
    }
}


protocol FTDistributedLockProtocol {
    func lock(id: String) -> Bool
    func unlock(id: String)
}

class FTTransectionLock: FTDistributedLockProtocol {
    func lock(id: String) -> Bool {
        return FTDistributedLock.share().lockTransectionId(id)
    }
    
    func unlock(id: String) {
        FTDistributedLock.share().unlockTransectionId(id)
    }
}

class FTTransection {
    private let id: String
    private let buyerId: Int?
    private let sellerId: Int?
    private let productId: Int
    private let orderId: String
    private var createTimeStamp: TimeInterval
    private var amount: Double
    private var status: FTTransectionStatus
    private var walletTransectionId: String?
    
    private var lock: FTDistributedLockProtocol?
    private var service: FTWallerRpcService?
    
    init(preAssignedId: String?,
         id: String,
         buyerId: Int?,
         sellerId: Int?,
         productId: Int,
         orderId: String,
         amount: Double) {
        self.id = FTTransection.getId(preAssignedId: preAssignedId)
        self.buyerId = buyerId
        self.sellerId = sellerId
        self.productId = productId
        self.orderId = orderId
        self.createTimeStamp = Date().timeIntervalSince1970
        self.amount = 0
        self.status = .ToBeExecuted
    }
    
    private static func getId(preAssignedId: String?) -> String {
        var id = ""
        if let preAssignedId = preAssignedId, !preAssignedId.isEmpty {
            id = preAssignedId
        } else {
            id = FTIDGenerator.generateId()
        }
        
        if !id.starts(with: "t_") {
            id = "t_" + (preAssignedId ?? "0")
        }
        return id
    }
    
    func executed() -> Bool {
        if (buyerId == nil) ||
            (sellerId == nil) ||
            (amount < 0) {
            return false
        }
        
        if status == .Executed { return true }
        
        let isLocked = self.lock?.lock(id: id) ?? false
        if !isLocked { return false }
        
        if status == .Executed { return true }
        
        if self.expired() { return false }
        
        let walletTransectionId = self.service?.moveMoney(id: id, buyerId: buyerId!, sellerid: sellerId!)
        self.walletTransectionId = walletTransectionId
        status = (walletTransectionId != nil) ? .Executed : .Fail
        if isLocked { }
        return status == .Executed
    }
    
    func setLock(lock: FTDistributedLockProtocol) {
        self.lock = lock
    }
    
    func setService(service: FTWallerRpcService) {
        self.service = service
    }
    
    func expired() -> Bool {
        return Date().timeIntervalSince1970 - createTimeStamp > 14 * 24 * 3600
    }
}

//全局变量：可能被多个测试用例共享
//静态方法：难以mock，FTIDGenerator很简单，无需mock
//复杂继承：如果一个属性需要mock，那么其它所有子类都需要mock
//高耦合代码：需要mock的对象太多
