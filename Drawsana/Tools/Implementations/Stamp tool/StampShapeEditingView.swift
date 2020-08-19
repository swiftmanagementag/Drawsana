//
//  StampShapeEditingView.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class StampShapeEditingView: UIView {
    /// Upper left 'delete' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public let deleteControlView = UIView()
    /// Lower right 'rotate' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public let resizeAndRotateControlView = UIView()
    /// Right side handle to change width of text. You may add any subviews you
    /// want, set border & background color, etc.
    public let changeImageControlView = UIView()

    public enum DragActionType {
        case delete
        case resizeAndRotate
        case changeImage
    }

    public struct Control {
        public let view: UIView
        public let dragActionType: DragActionType
    }

    public private(set) var controls = [Control]()

    init() {
        super.init(frame: .zero)

        clipsToBounds = false
        backgroundColor = UIColor.clear
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1.0
        layer.isOpaque = false

        for v in [deleteControlView, resizeAndRotateControlView, changeImageControlView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            v.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
            v.layer.cornerRadius = 4
            v.layer.masksToBounds = true
        }
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    public func addStandardControls() {
        addControl(dragActionType: .delete, view: deleteControlView) { containerView, deleteControlView in
            NSLayoutConstraint.activate(deprioritize([
                deleteControlView.widthAnchor.constraint(equalToConstant: 36),
                deleteControlView.heightAnchor.constraint(equalToConstant: 36),
                deleteControlView.rightAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0),
                deleteControlView.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            ]))
        }

        addControl(dragActionType: .changeImage, view: changeImageControlView) { containerView, changeImageControlView in
            NSLayoutConstraint.activate(deprioritize([
                changeImageControlView.widthAnchor.constraint(equalToConstant: 36),
                changeImageControlView.heightAnchor.constraint(equalToConstant: 36),
                changeImageControlView.leftAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0),
                changeImageControlView.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            ]))
        }

        addControl(dragActionType: .resizeAndRotate, view: resizeAndRotateControlView) { containerView, resizeAndRotateControlView in
            NSLayoutConstraint.activate(deprioritize([
                resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: 36),
                resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: 36),
                resizeAndRotateControlView.leftAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0),
                resizeAndRotateControlView.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0),
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

        let i = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 36)))
        i.text = "📷"
        i.textAlignment = .center
        changeImageControlView.addSubview(i)
    }

    public func addControl<T: UIView>(dragActionType: DragActionType, view: T, applyConstraints: (UIView, T) -> Void) {
        addSubview(view)
        controls.append(Control(view: view, dragActionType: dragActionType))

        applyConstraints(self, view)
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
