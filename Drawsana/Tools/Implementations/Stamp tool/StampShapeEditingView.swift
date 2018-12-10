//
//  TextShapeEditingView.swift
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

  /// The `UITextView` that the user interacts with during editing
  public let imageView: UIImageView

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

  init(imageView: UIImageView) {
    self.imageView = imageView
    super.init(frame: .zero)

    clipsToBounds = false
    backgroundColor = .clear
    layer.isOpaque = false

    imageView.translatesAutoresizingMaskIntoConstraints = false

    deleteControlView.translatesAutoresizingMaskIntoConstraints = false
    deleteControlView.backgroundColor = .red

    resizeAndRotateControlView.translatesAutoresizingMaskIntoConstraints = false
    resizeAndRotateControlView.backgroundColor = .green

    changeImageControlView.translatesAutoresizingMaskIntoConstraints = false
    changeImageControlView.backgroundColor = .yellow

    addSubview(imageView)

    NSLayoutConstraint.activate([
      imageView.leftAnchor.constraint(equalTo: leftAnchor),
      imageView.rightAnchor.constraint(equalTo: rightAnchor),
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    return imageView.sizeThatFits(size)
  }

  public func addStandardControls() {
    addControl(dragActionType: .delete, view: deleteControlView) { (imageView, deleteControlView) in
      NSLayoutConstraint.activate(deprioritize([
        deleteControlView.widthAnchor.constraint(equalToConstant: 36),
        deleteControlView.heightAnchor.constraint(equalToConstant: 36),
        deleteControlView.rightAnchor.constraint(equalTo: imageView.leftAnchor),
        deleteControlView.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -3),
      ]))
    }

    addControl(dragActionType: .resizeAndRotate, view: resizeAndRotateControlView) { (imageView, resizeAndRotateControlView) in
      NSLayoutConstraint.activate(deprioritize([
        resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: 36),
        resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: 36),
        resizeAndRotateControlView.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 5),
        resizeAndRotateControlView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
      ]))
    }

    addControl(dragActionType: .changeImage, view: changeImageControlView) { (imageView, changeWidthControlView) in
      NSLayoutConstraint.activate(deprioritize([
        changeWidthControlView.widthAnchor.constraint(equalToConstant: 36),
        changeWidthControlView.heightAnchor.constraint(equalToConstant: 36),
        changeWidthControlView.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 5),
        changeWidthControlView.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -4),
      ]))
    }
  }

  public func addControl<T: UIView>(dragActionType: DragActionType, view: T, applyConstraints: (UIImageView, T) -> Void) {
    addSubview(view)
    controls.append(Control(view: view, dragActionType: dragActionType))
    applyConstraints(imageView, view)
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
