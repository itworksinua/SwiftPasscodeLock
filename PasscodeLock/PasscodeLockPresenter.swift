//
//  PasscodeLockPresenter.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/29/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

open class PasscodeLockPresenter {
    
    fileprivate var mainWindow: UIWindow?
    
    fileprivate lazy var passcodeLockWindow: UIWindow = {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        window.windowLevel = UIWindow.Level(rawValue: 0)
        window.makeKeyAndVisible()
        
        return window
    }()
    
    fileprivate let passcodeConfiguration: PasscodeLockConfigurationType
    fileprivate let passcodeState: PasscodeLockStateType
    
    public let passcodeLockVC: PasscodeLockViewController
    open var isPasscodePresented = false
    
    public init(mainWindow window: UIWindow?,
                configuration: PasscodeLockConfigurationType,
                state: PasscodeLockStateType,
                wrongPinAnimation: PinCodeShakeAnimationOptions = PinCodeShakeAnimationOptionsDefault)
    {
        mainWindow = window
        mainWindow?.windowLevel = UIWindow.Level(rawValue: 1)
        passcodeConfiguration = configuration
        passcodeState = state
        passcodeLockVC = PasscodeLockViewController(state: passcodeState,
                                                    configuration: passcodeConfiguration,
                                                    wrongPinAnimation: wrongPinAnimation)
    }
    
    open func presentPasscodeLock() {
        guard passcodeConfiguration.repository.hasPasscode else { return }
        guard !isPasscodePresented else { return }
        
        isPasscodePresented = true
        
        passcodeLockWindow.windowLevel = UIWindow.Level(rawValue: 2)
        passcodeLockWindow.isHidden = false
        
        mainWindow?.windowLevel = UIWindow.Level(rawValue: 1)
        mainWindow?.endEditing(true)

        let userDismissCompletionCallback = passcodeLockVC.dismissCompletionCallback
        
        passcodeLockVC.dismissCompletionCallback = { [weak self] in
            userDismissCompletionCallback?()
            self?.dismissPasscodeLock()
        }
        
        passcodeLockWindow.rootViewController = passcodeLockVC
    }
    
    open func dismissPasscodeLock(animated: Bool = true) {
        isPasscodePresented = false
        mainWindow?.windowLevel = UIWindow.Level(rawValue: 1)
        mainWindow?.makeKeyAndVisible()
        
        if animated {
            animatePasscodeLockDismissal()
        } else {
            passcodeLockWindow.windowLevel = UIWindow.Level(rawValue: 0)
            passcodeLockWindow.rootViewController = nil
        }
    }
    
    internal func animatePasscodeLockDismissal() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: UIView.AnimationOptions(),
            animations: { [weak self] in
                self?.passcodeLockWindow.alpha = 0
            },
            completion: { [weak self] _ in
                self?.passcodeLockWindow.windowLevel = UIWindow.Level(rawValue: 0)
                self?.passcodeLockWindow.rootViewController = nil
                self?.passcodeLockWindow.alpha = 1
            }
        )
    }
}
