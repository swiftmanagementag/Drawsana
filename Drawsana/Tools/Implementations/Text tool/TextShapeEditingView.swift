//
//  TextShapeEditingView.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class TextShapeEditingView: UIView {
    /// Upper left 'delete' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public let deleteControlView = UIView()
    /// Lower right 'rotate' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public let resizeAndRotateControlView = UIView()
    /// Right side handle to change width of text. You may add any subviews you
    /// want, set border & background color, etc.
    public let changeWidthControlView = UIView()

    /// The `UITextView` that the user interacts with during editing
    public let textView: UITextView

    public enum DragActionType {
        case delete
        case resizeAndRotate
        case changeWidth
    }

    public struct Control {
        public let view: UIView
        public let dragActionType: DragActionType
    }

    public private(set) var controls = [Control]()

    init(textView: UITextView) {
        self.textView = textView
        super.init(frame: .zero)

        clipsToBounds = false
        backgroundColor = .clear
        layer.isOpaque = false
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0

        textView.translatesAutoresizingMaskIntoConstraints = false

        for v in [deleteControlView, resizeAndRotateControlView, changeWidthControlView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
            v.layer.cornerRadius = 4
            v.layer.masksToBounds = true
        }

        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: leftAnchor),
            textView.rightAnchor.constraint(equalTo: rightAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        return textView.sizeThatFits(size)
    }

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    @discardableResult
    override public func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }

    public func addStandardControls() {
        addControl(dragActionType: .delete, view: deleteControlView) { textView, deleteControlView in
            NSLayoutConstraint.activate(deprioritize([
                deleteControlView.widthAnchor.constraint(equalToConstant: 36),
                deleteControlView.heightAnchor.constraint(equalToConstant: 36),
                deleteControlView.rightAnchor.constraint(equalTo: textView.leftAnchor, constant: -2),
                deleteControlView.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: -2),
            ]))
        }

        addControl(dragActionType: .resizeAndRotate, view: resizeAndRotateControlView) { textView, resizeAndRotateControlView in
            NSLayoutConstraint.activate(deprioritize([
                resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: 36),
                resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: 36),
                resizeAndRotateControlView.leftAnchor.constraint(equalTo: textView.rightAnchor, constant: -2),
                resizeAndRotateControlView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: -2),
            ]))
        }

        addControl(dragActionType: .changeWidth, view: changeWidthControlView) { textView, changeWidthControlView in
            NSLayoutConstraint.activate(deprioritize([
                changeWidthControlView.widthAnchor.constraint(equalToConstant: 36),
                changeWidthControlView.heightAnchor.constraint(equalToConstant: 36),
                changeWidthControlView.leftAnchor.constraint(equalTo: textView.rightAnchor, constant: -2),
                changeWidthControlView.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: -2),
            ]))
        }

        let x = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 36)))
        x.text = "🗑️"
        x.textAlignment = .center
        deleteControlView.addSubview(x)

        let o = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 36)))
        o.text = "🌀"
        o.textAlignment = .center
        resizeAndRotateControlView.addSubview(o)

        let w = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 36)))
        w.text = "📏" // ↔️"
        w.textAlignment = .center
        changeWidthControlView.addSubview(w)
    }

    public func addControl<T: UIView>(dragActionType: DragActionType, view: T, applyConstraints: (UITextView, T) -> Void) {
        addSubview(view)
        controls.append(Control(view: view, dragActionType: dragActionType))
        applyConstraints(textView, view)
    }

    public func getDragActionType(point: CGPoint) -> DragActionType? {
        guard let superview = superview else { return .none }
        for control in controls {
            if control.view.convert(control.view.bounds, to: superview).contains(point) {
                return control.dragActionType
            }
        }
        return nil
    }
}

private func deprioritize(_ constraints: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
    for constraint in constraints {
        constraint.priority = .defaultLow
    }
    return constraints
}
