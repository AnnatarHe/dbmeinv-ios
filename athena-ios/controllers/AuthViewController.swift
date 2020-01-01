//
//  AuthViewController.swift
//  athena-ios
//
//  Created by AnnatarHe on 20/09/2017.
//  Copyright © 2017 AnnatarHe. All rights reserved.
//

import UIKit
import LocalAuthentication
import SQLite
import Sentry
import KeychainSwift

class AuthViewController: BaseViewController {
    
    private var loading = false
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func fingerLogin(_ sender: Any) {
        self.fingerCheck()
    }
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBAction func login(_ sender: Any) {

        if (self.loading) {
            return
        }

        guard let _email = email.text else {
            showErrorMsg(title: "email error")
            return
        }
        guard let _pwd = password.text else {
            showErrorMsg(title: "password error")
            return
        }
        indicator.startAnimating()

        Config.getApolloClient().fetch(query: AuthQuery.init(email: _email, password: _pwd)) { result in
            
            self.indicator.stopAnimating()
            self.loading = false
            switch result {
            case .success(let data):
                Config.token = (data.data?.auth?.token)!
                Config.userId = (data.data?.auth?.id)!
                let keychain = KeychainSwift()
                keychain.set(_email, forKey: "email")
                keychain.set(_pwd, forKey: "pwd")
                
                // setup sentry user
                let sentryUser = User(userId: (data.data?.auth?.id)!)
                sentryUser.email = _email
                
                Client.shared?.user = sentryUser
                self.backToProfile()
            case .failure(let err):
                self.showErrorMsg(title: "error")
                return
                
            }

        }
    }
    
    private func showErrorMsg(title: String) {
        let alert = UIAlertController(title: title, message: title, preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        indicator.hidesWhenStopped = true
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createGradientLayer()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func backToProfile() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func fingerCheck() {
    
        let context = LAContext()
        var err: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            print(err)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "请指纹解锁", reply: { success, error in
            guard success == true else {
                print(error)
                return
            }
            if success {
                // dismiss and reload data
                
                let keychainSwift = KeychainSwift()
                guard let email = keychainSwift.get("email"), let pwd = keychainSwift.get("pwd") else {
                    self.showErrorMsg(title: "please login with email and password in first time")
                    return
                }
                
                DispatchQueue.main.async {
                    self.email.text = email
                    self.password.text = pwd
                    self.login(self)
                }
                return
                
            }
            
            if let error = error as NSError? {
                // 获取错误信息
                let message = self.errorMessageForLAErrorCode(errorCode: error.code)
                print(message)
                self.showErrorMsg(title: message)
            }
            
        })
    
    }
    
    private func errorMessageForLAErrorCode(errorCode: Int) -> String {
        var message = ""
        
        switch errorCode {
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
            
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"
            
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
            
        case LAError.biometryLockout.rawValue:
            message = "Too many failed attempts."
            
        case LAError.biometryNotAvailable.rawValue:
            message = "TouchID is not available on the device"
            
        case LAError.userCancel.rawValue:
            message = "The user did cancel"
            
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
            
        default:
            message = "Did not find error code on LAError object"
        }
        return message
    }
    
    private func createGradientLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [AthenaColors.blue.cgColor, AthenaColors.green.cgColor]
        gradientLayer.startPoint = CGPoint(x: 1, y: 0.2)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0.8)
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
}
