//
//  IQKeyboardManager+Internal.swift
//  https://github.com/hackiftekhar/IQKeyboardManager
//  Copyright (c) 2013-24 Iftekhar Qurashi.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import IQTextFieldViewListener
import IQKeyboardManagerCore

@available(iOSApplicationExtension, unavailable)
internal extension IQKeyboardManager {

    func registerActiveStateChangeForTouchOutside() {
        self.activeConfiguration.registerChange(identifier: "resignOnTouchOutside",
                                                changeHandler: { [weak self] event, _, textFieldInfo in
            guard let self = self else { return }
            switch event {
            case .hide:
                // Removing gesture recognizer (Enhancement ID: #14)
                textFieldInfo?.textFieldView.window?.removeGestureRecognizer(resignGesture)
            case .show:
                // Adding gesture recognizer (Enhancement ID: #14)
                textFieldInfo?.textFieldView.window?.addGestureRecognizer(resignGesture)

                updateResignGestureState()
            case .change:
                updateResignGestureState()
            }
        })
    }

    func unregisterActiveStateChangeForTouchOutside() {
        self.activeConfiguration.unregisterChange(identifier: "resignOnTouchOutside")
    }

    func updateResignGestureState() {
        resignGesture.isEnabled = privateResignOnTouchOutside()
    }

    // swiftlint:disable cyclomatic_complexity
    private func privateResignOnTouchOutside() -> Bool {

        var isEnabled: Bool = resignOnTouchOutside

        guard let textFieldViewInfo: IQTextFieldViewInfo = activeConfiguration.textFieldViewInfo else {
            return isEnabled
        }

        let enableMode: IQEnableMode = textFieldViewInfo.textFieldView.iq.resignOnTouchOutsideMode

        switch enableMode {
        case .default:
            guard var textFieldViewController = textFieldViewInfo.textFieldView.iq.viewContainingController() else {
                return isEnabled
            }

            // If it is searchBar textField embedded in Navigation Bar
            if textFieldViewInfo.textFieldView.iq.textFieldSearchBar() != nil,
               let navController: UINavigationController = textFieldViewController as? UINavigationController,
               let topController: UIViewController = navController.topViewController {
                textFieldViewController = topController
            }

            // If viewController is kind of enable viewController class, then assuming resignOnTouchOutside is enabled.
            if !isEnabled,
               enabledTouchResignedClasses.contains(where: { textFieldViewController.isKind(of: $0) }) {
                isEnabled = true
            }

            if isEnabled {

                // If viewController is kind of disable viewController class,
                // then assuming resignOnTouchOutside is disable.
                if disabledTouchResignedClasses.contains(where: { textFieldViewController.isKind(of: $0) }) {
                    isEnabled = false
                }

                // Special Controllers
                if isEnabled {

                    let classNameString: String = "\(type(of: textFieldViewController.self))"

                    // _UIAlertControllerTextFieldViewController
                    if classNameString.contains("UIAlertController"),
                       classNameString.hasSuffix("TextFieldViewController") {
                        isEnabled = false
                    }
                }
            }
            return isEnabled
        case .enabled:
            return true
        case .disabled:
            return false
        }
    }
    // swiftlint:enable cyclomatic_complexity
}