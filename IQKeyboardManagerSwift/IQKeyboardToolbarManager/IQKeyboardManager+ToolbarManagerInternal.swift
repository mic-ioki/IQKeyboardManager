//
//  IQKeyboardManager+ToolbarManagerInternal.swift
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

@available(iOSApplicationExtension, unavailable)
internal extension IQKeyboardToolbarManager {

    /**    Get all UITextField/UITextView siblings of textFieldView. */
    func responderViews(of textFieldView: UIView) -> [UIView]? {

        var superConsideredView: UIView?

        // If find any consider responderView in it's upper hierarchy then will get deepResponderView.
        for allowedClass in toolbarPreviousNextAllowedClasses {
            superConsideredView = textFieldView.iq.superviewOf(type: allowedClass)
            if superConsideredView != nil {
                break
            }
        }

        var swiftUIHostingView: UIView?
        let swiftUIHostingViewName: String = "UIHostingView<"
        var superView: UIView? = textFieldView.superview
        while let unwrappedSuperView: UIView = superView {

            let classNameString: String = {
                var name: String = "\(type(of: unwrappedSuperView.self))"
                if name.hasPrefix("_") {
                    name.removeFirst()
                }
                return name
            }()

            if classNameString.hasPrefix(swiftUIHostingViewName) {
                swiftUIHostingView = unwrappedSuperView
                break
            }

            superView = unwrappedSuperView.superview
        }

        // (Enhancement ID: #22)
        // If there is a superConsideredView in view's hierarchy,
        // then fetching all it's subview that responds.
        // No sorting for superConsideredView, it's by subView position.
        if let view: UIView = swiftUIHostingView {
            return view.iq.deepResponderViews()
        } else if let view: UIView = superConsideredView {
            return view.iq.deepResponderViews()
        } else {  // Otherwise fetching all the siblings

            let textFields: [UIView] = textFieldView.iq.responderSiblings()

            // Sorting textFields according to behavior
            switch toolbarConfiguration.manageBehavior {
            // If autoToolbar behavior is bySubviews, then returning it.
            case .bySubviews:   return textFields

            // If autoToolbar behavior is by tag, then sorting it according to tag property.
            case .byTag:    return textFields.sortedByTag()

            // If autoToolbar behavior is by tag, then sorting it according to tag property.
            case .byPosition:    return textFields.sortedByPosition()
            }
        }
    }

    func privateIsEnableAutoToolbar(of textFieldView: UIView) -> Bool {

        var isEnabled: Bool = enableAutoToolbar

        guard var textFieldViewController = textFieldView.iq.viewContainingController() else {
            return isEnabled
        }

        // If it is searchBar textField embedded in Navigation Bar
        if textFieldView.iq.textFieldSearchBar() != nil,
           let navController: UINavigationController = textFieldViewController as? UINavigationController,
           let topController: UIViewController = navController.topViewController {
            textFieldViewController = topController
        }

        if !isEnabled, enabledToolbarClasses.contains(where: { textFieldViewController.isKind(of: $0) }) {
            isEnabled = true
        }

        if isEnabled {

            // If found any toolbar disabled classes then return.
            if disabledToolbarClasses.contains(where: { textFieldViewController.isKind(of: $0) }) {
                isEnabled = false
            }

            // Special Controllers
            if isEnabled {

                let classNameString: String = "\(type(of: textFieldViewController.self))"

                // _UIAlertControllerTextFieldViewController
                if classNameString.contains("UIAlertController"), classNameString.hasSuffix("TextFieldViewController") {
                    isEnabled = false
                }
            }
        }

        return isEnabled
    }
}
