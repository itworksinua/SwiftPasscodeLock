//
//  SetPasscodeState.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import Foundation

struct SetPasscodeState: PasscodeLockStateType {
    
    let title: String
    let description: String
    let isCancellableAction = true
    var isTouchIDAllowed = false
    
    init(title: String, description: String) {
        
        self.title = title
        self.description = description
    }
    
    init(forNew:Bool = false) {
        
        title = localizedStringFor("PasscodeLockSetTitle", comment: "Set passcode title")
        
        description = forNew ? "" :localizedStringFor("PasscodeLockSetDescription", comment: "Set passcode description")
    }
    
    func acceptPasscode(_ passcode: [String], fromLock lock: PasscodeLockType) {
        
        let nextState = ConfirmPasscodeState(passcode: passcode)
        
        lock.changeStateTo(nextState)
    }
}
