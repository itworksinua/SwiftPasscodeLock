//
//  PasscodeLockViewController.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

public typealias PasscodeLockCallback = ((_ lock: PasscodeLockType) -> Void)?

public protocol PasscodeDelegate {
    func passcodeEntered(_ lock: PasscodeLockType, passcode: String)
    func forgotPasscode()
    func newButtonTapped()
}

public extension PasscodeDelegate {
    func forgotPasscode() {}
}

extension UIColor {
    public convenience init?(hexString: String) {
        let r, g, b, a: CGFloat
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
    
    static var customHighlightDigitColor: UIColor {
        return UIColor(hexString: "#29b6f6ff")!
        // return .blue
    }
}

open class PasscodeLockViewController: UIViewController, PasscodeLockTypeDelegate {
    public enum LockState {
        case enterPasscode
        case setPasscode
        case changePasscode
        case removePasscode
        
        public func getState() -> PasscodeLockStateType {
            switch self {
            case .enterPasscode: return EnterPasscodeState()
            case .setPasscode: return SetPasscodeState()
            case .changePasscode: return SetPasscodeState(forNew: true)
            case .removePasscode: return EnterPasscodeState(allowCancellation: true)
            }
        }
    }
    
    @IBOutlet open weak var titleLabel: UILabel?
    @IBOutlet open weak var descriptionLabel: UILabel?
    
    open var placeholders: [PasscodeSignPlaceholderView] {
        return placeholderContainerView.arrangedSubviews.compactMap { $0 as? PasscodeSignPlaceholderView }
    }
    
    @IBOutlet open weak var placeholderContainerView: UIStackView!
    @IBOutlet open weak var cancelButton: UIButton?
    @IBOutlet open weak var deleteSignButton: UIButton?
    
    @IBOutlet open weak var loadingImage: UIImageView?
    
    @IBOutlet open weak var loadingView: UIView?
    
    @IBOutlet open weak var touchIDButton: UIButton?
    @IBOutlet open weak var placeholdersX: NSLayoutConstraint?
    @IBOutlet open weak var backButton: UIButton?
    @IBOutlet open weak var topConstraint: NSLayoutConstraint!
    @IBOutlet open weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet open weak var bottomButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet open var digitButtonCollection: [PasscodeSignButton]!
    @IBOutlet open weak var digitButtonHeightConstraint: NSLayoutConstraint?
    @IBOutlet open weak var digitButtonWidthConstraint: NSLayoutConstraint?
    
    open var successCallback: PasscodeLockCallback
    open var failureCallback: PasscodeLockCallback
    
    private var isButtonTapAfterTry = false
    
    open var delegate: PasscodeDelegate?
    open var showBackButton: Bool = false
    open var needDismisAfterConfirm: Bool = true
    
    open var dismissCompletionCallback: (() -> Void)?
    open var animateOnDismiss: Bool
    open var notificationCenter: NotificationCenter?
    
    open var animatedAppearLoadingView: Bool = true
    
    open var loadViewIsHidden: Bool {
        return ((loadingView?.alpha ?? 0.0) == 0.0) || (loadingView?.isHidden ?? true)
    }
    
    open var wrongPinCodeAnimationOptions: PinCodeShakeAnimationOptions
    
    internal let passcodeConfiguration: PasscodeLockConfigurationType
    internal var passcodeLock: PasscodeLockType
    internal var isPlaceholdersAnimationCompleted = true
    
    fileprivate var shouldTryToAuthenticateWithBiometrics = true
    
    open var passcodeLockState: PasscodeLockStateType {
        return passcodeLock.state
    }
    
    // MARK: - Initializers
    
    public init(state: PasscodeLockStateType,
                configuration: PasscodeLockConfigurationType,
                animateOnDismiss: Bool = true,
                wrongPinAnimation: PinCodeShakeAnimationOptions = PinCodeShakeAnimationOptionsDefault) {
        self.animateOnDismiss = animateOnDismiss
        
        passcodeConfiguration = configuration
        passcodeLock = PasscodeLock(state: state, configuration: configuration)
        wrongPinCodeAnimationOptions = wrongPinAnimation
        
        let nibName = "PasscodeLockView\(UIDevice.current.userInterfaceIdiom == .phone ? "" : "IPad")"
        let bundle: Bundle = bundleForResource(nibName, ofType: "nib")
        
        super.init(nibName: nibName, bundle: bundle)
        
        passcodeLock.delegate = self
        notificationCenter = NotificationCenter.default
    }
    
    public convenience init(state: LockState, configuration: PasscodeLockConfigurationType, animateOnDismiss: Bool = true, wrongPinAnimation: PinCodeShakeAnimationOptions = PinCodeShakeAnimationOptionsDefault) {
        self.init(state: state.getState(), configuration: configuration, animateOnDismiss: animateOnDismiss, wrongPinAnimation: wrongPinAnimation)
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        clearEvents()
    }
    
    // MARK: - View
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        updatePasscodeView()
        // deleteSignButton?.isEnabled = false
        
        setupEvents()
        backButton?.isHidden = !showBackButton
        
        for placeholder in placeholders {
            placeholder.layer.borderWidth = 0
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            configureDesignByDevice()
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldTryToAuthenticateWithBiometrics {
            authenticateWithBiometrics()
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nc = navigationController {
            nc.isNavigationBarHidden = true
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let nc = navigationController {
            nc.isNavigationBarHidden = false
        }
    }
    
    func configureDesignByDevice() {
        digitButtonCollection?.forEach { $0.highlightBackgroundColor = .customHighlightDigitColor }
        
        var titleFont: UIFont?
        var descriptionFont: UIFont?
        var topConstant: CGFloat
        var buttonWidth: CGFloat = 48
        var buttonHeight: CGFloat = 48
        var buttonFontSize: CGFloat = 28
        var bottomConstant: CGFloat
        var bottomButtomConstant: CGFloat = 24
        
        let screenRect = UIScreen.main.bounds
        if screenRect.width == 320 && screenRect.height == 568 { // se
            titleFont = .robotoMedium(14)
            descriptionFont = .robotoMedium(12)
            
            topConstant = 64
            bottomConstant = 96
        } else if screenRect.width == 414 && screenRect.height == 736 { // 414 × 736 8+
            titleFont = .robotoMedium(18)
            descriptionFont = .robotoMedium(14)
            
            topConstant = 94
            bottomConstant = 112
            bottomButtomConstant = 28
            
            buttonWidth = 60
            buttonHeight = 60
            buttonFontSize = 32
        } else if screenRect.width == 375 && screenRect.height == 812 { // 375 x 812 X
            titleFont = .robotoMedium(18)
            descriptionFont = .robotoMedium(14)
            
            topConstant = 94
            bottomConstant = 112
            bottomButtomConstant = 28
        } else { // 375 × 667 8
            titleFont = .robotoMedium(16)
            descriptionFont = .robotoMedium(14)
            
            topConstant = 104
            bottomConstant = 100
        }
        
        digitButtonWidthConstraint?.constant = buttonWidth
        digitButtonHeightConstraint?.constant = buttonHeight
        digitButtonCollection?.forEach { $0.titleLabel?.font = .robotoRegular(buttonFontSize) }
        bottomConstraint?.constant = bottomConstant
        bottomButtonConstraint?.constant = bottomButtomConstant
        topConstraint?.constant = topConstant
        titleLabel?.font = titleFont
        descriptionLabel?.font = descriptionFont
        
        touchIDButton?.isHidden = (passcodeLockState is SetPasscodeState) || (passcodeLockState is ConfirmPasscodeState)
    }
    
    internal func updatePasscodeView() {
        titleLabel?.text = passcodeLock.state.title
        descriptionLabel?.text = passcodeLock.state.description
        if !passcodeLock.state.isCancellableAction {
            cancelButton?.setTitle("", for: .normal)
        }
        touchIDButton?.isHidden = (passcodeLockState is SetPasscodeState) || (passcodeLockState is ConfirmPasscodeState)
    }
    
    // MARK: - Events
    
    fileprivate func setupEvents() {
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appWillEnterForegroundHandler(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appDidEnterBackgroundHandler(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    fileprivate func clearEvents() {
        notificationCenter?.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc open func appWillEnterForegroundHandler(_ notification: Notification) {
        authenticateWithBiometrics()
    }
    
    @objc open func appDidEnterBackgroundHandler(_ notification: Notification) {
        shouldTryToAuthenticateWithBiometrics = false
    }
    
    func configButtons(_ sender: UIButton, lock: Bool) {
        digitButtonCollection?.forEach { if $0 != sender { $0.isUserInteractionEnabled = !lock } }
        deleteSignButton?.isUserInteractionEnabled = !lock
    }
    
    open func configButtons(lock: Bool) {
        if let deleteSignButton = deleteSignButton {
            configButtons(deleteSignButton, lock: lock)
        }
    }
    
    open func cleanLongPress() {
        var amount = passcodeLock.passcode.count
        
        while amount > 0 {
            deleteSignButtonTap(nil)
            amount -= 1
        }
    }
    
    // MARK: - Actions
    
    @IBAction func passcodeSignButtonTap(_ sender: PasscodeSignButton) {
        guard isPlaceholdersAnimationCompleted, loadViewIsHidden else { return }
        
        configButtons(sender, lock: true)
        passcodeLock.addSign(sender.passcodeSign)
        if isButtonTapAfterTry {
            isButtonTapAfterTry = false
            delegate?.newButtonTapped()
        }
        configButtons(sender, lock: false)
    }
    
    @IBAction func cancelButtonTap(_ sender: UIButton) {
        dismissPasscodeLock(passcodeLock)
    }
    
    @IBAction func deleteSignButtonTap(_ sender: UIButton?) {
        passcodeLock.removeSign()
        
        if isButtonTapAfterTry {
            isButtonTapAfterTry = false
            delegate?.newButtonTapped()
        }
    }
    
    @IBAction func touchIDButtonTap(_ sender: UIButton) {
        passcodeLock.authenticateWithBiometrics()
    }
    
    @IBAction func forgotPasscode(_ sender: UIButton) {
        delegate?.forgotPasscode()
        if isButtonTapAfterTry {
            isButtonTapAfterTry = false
            delegate?.newButtonTapped()
        }
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        cancelButtonTap(sender)
    }
    
    fileprivate func authenticateWithBiometrics() {
        if passcodeConfiguration.shouldRequestTouchIDImmediately && passcodeLock.isTouchIDAllowed {
            passcodeLock.authenticateWithBiometrics()
        }
    }
    
    internal func dismissPasscodeLock(_ lock: PasscodeLockType, completionHandler: (() -> Void)? = nil) {
        // if presented as modal
        if presentingViewController?.presentedViewController == self {
            dismiss(animated: animateOnDismiss) { [weak self] () in
                
                self?.dismissCompletionCallback?()
                
                completionHandler?()
            }
            
            return
            
                // if pushed in a navigation controller
        } else if navigationController != nil {
            navigationController?.popViewController(animated: animateOnDismiss)
        }
        
        dismissCompletionCallback?()
        
        completionHandler?()
    }
    
    // MARK: - Animations
    
    internal func animateWrongPassword() {
        isPlaceholdersAnimationCompleted = false
        animatePlaceholders(placeholders, toState: .error)
        
        placeholderContainerView.shake(direction: wrongPinCodeAnimationOptions.direction,
                                       duration: wrongPinCodeAnimationOptions.duration,
                                       animationType: wrongPinCodeAnimationOptions.animationType,
                                       swingLength: wrongPinCodeAnimationOptions.swingLength,
                                       swingCount: wrongPinCodeAnimationOptions.swingCount,
                                       isDamping: wrongPinCodeAnimationOptions.isDamping) {
            self.isPlaceholdersAnimationCompleted = true
            self.animatePlaceholders(self.placeholders, toState: .inactive)
        }
        
        isButtonTapAfterTry = true
    }
    
    internal func animatePlaceholders(_ placeholders: [PasscodeSignPlaceholderView], toState state: PasscodeSignPlaceholderView.State) {
        for placeholder in placeholders {
            placeholder.animateState(state)
        }
    }
    
    fileprivate func animatePlacehodlerAtIndex(_ index: Int, toState state: PasscodeSignPlaceholderView.State) {
        guard index < placeholders.count && index >= 0 else { return }
        
        placeholders[index].animateState(state)
        for placeholder in 0..<index {
            placeholders[placeholder].animateState(.active)
        }
    }
    
    // MARK: - PasscodeLockDelegate
    
    open func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
        // deleteSignButton?.isEnabled = true
        animatePlaceholders(placeholders, toState: .inactive)
        if needDismisAfterConfirm {
            dismissPasscodeLock(lock) { [weak self] () in
                self?.successCallback?(lock)
            }
        } else {
            successCallback?(lock)
        }
    }
    
    open func passcodeLockDidFail(_ lock: PasscodeLockType) {
        animateWrongPassword()
        failureCallback?(lock)
    }
    
    open func passcodeLockDidChangeState(_ lock: PasscodeLockType) {
        updatePasscodeView()
        animatePlaceholders(placeholders, toState: .inactive)
        // deleteSignButton?.isEnabled = false
    }
    
    open func passcodeLock(_ lock: PasscodeLockType, addedSignAtIndex index: Int) {
        animatePlacehodlerAtIndex(index, toState: .active)
        // deleteSignButton?.isEnabled = true
    }
    
    open func passcodeLock(_ lock: PasscodeLockType, removedSignAtIndex index: Int) {
        animatePlacehodlerAtIndex(index, toState: .inactive)
        
        if index == 0 {
            // deleteSignButton?.isEnabled = false
        }
    }
    
    open func passcodeEntered(_ lock: PasscodeLockType, passcode: String) {
        //        rotateImage()
        delegate?.passcodeEntered(lock, passcode: passcode)
    }
    
    open func rotateImage() {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.duration = 2.0
        rotateAnimation.repeatCount = Float.infinity
        loadingImage?.layer.add(rotateAnimation, forKey: "rotate")
        
        showLoadingView()
    }
    
    open func showLoadingView(animation: Bool? = nil) {
        var localAnimationVar = animatedAppearLoadingView
        if let animation = animation {
            localAnimationVar = animation
        }
        
        if loadingView?.isHidden ?? true {
            loadingView?.isHidden = false
        }
        
        if localAnimationVar {
            UIView.animate(withDuration: 0.3) {
                self.loadingView?.alpha = 1.0
            }
        } else {
            self.loadingView?.alpha = 1.0
        }
    }
    
    open func hideLoadingView(animation: Bool? = nil) {
        var localAnimationVar = animatedAppearLoadingView
        if let animation = animation {
            localAnimationVar = animation
        }
        
        if localAnimationVar {
            UIView.animate(withDuration: 0.3) {
                self.loadingView?.alpha = 0.0
            }
        } else {
            self.loadingView?.alpha = 0.0
        }
    }
}
