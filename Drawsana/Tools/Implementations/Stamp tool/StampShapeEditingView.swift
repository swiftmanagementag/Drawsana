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
	layer.borderColor = UIColor.red.cgColor
	layer.borderWidth = 2.0
    layer.isOpaque = false
	
	deleteControlView.translatesAutoresizingMaskIntoConstraints = false
    deleteControlView.backgroundColor = .red

    resizeAndRotateControlView.translatesAutoresizingMaskIntoConstraints = false
    resizeAndRotateControlView.backgroundColor = .green

    changeImageControlView.translatesAutoresizingMaskIntoConstraints = false
    changeImageControlView.backgroundColor = .yellow
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError()
  }
/*
  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    return imageView.sizeThatFits(size)
  }
*/
  public func addStandardControls() {
    addControl(dragActionType: .delete, view: deleteControlView) { (imageView, deleteControlView) in
      NSLayoutConstraint.activate(deprioritize([
        deleteControlView.widthAnchor.constraint(equalToConstant: 36),
        deleteControlView.heightAnchor.constraint(equalToConstant: 36),
        deleteControlView.rightAnchor.constraint(equalTo: self.leftAnchor),
        deleteControlView.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -3),
      ]))
    }

    addControl(dragActionType: .resizeAndRotate, view: resizeAndRotateControlView) { (imageView, resizeAndRotateControlView) in
      NSLayoutConstraint.activate(deprioritize([
        resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: 36),
        resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: 36),
        resizeAndRotateControlView.leftAnchor.constraint(equalTo: self.rightAnchor, constant: 5),
        resizeAndRotateControlView.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 4),
      ]))
    }

	let x = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 36)))
	x.text = "X"
	x.textAlignment = .center
	deleteControlView.addSubview(x)
	
	let o = UILabel(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 36, height: 36)))
	o.text = "O"
	o.textAlignment = .center
	resizeAndRotateControlView.addSubview(o)
	
  }

  public func addControl<T: UIView>(dragActionType: DragActionType, view: T, applyConstraints: (UIImageView, T) -> Void) {
    addSubview(view)
    controls.append(Control(view: view, dragActionType: dragActionType))
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
