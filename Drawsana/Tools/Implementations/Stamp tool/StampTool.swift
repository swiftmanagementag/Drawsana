//
//  StampTool.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit
import Drawsana

public protocol StampToolDelegate: AnyObject {
  /// Given the point where the user tapped, return the point where a Stamp
  /// shape should be created. You might want to set it to a specific point, or
  /// make sure it's above the keyboard.
  func stampToolPointForNewStamp(tappedPoint: CGPoint) -> CGPoint

  /// User tapped away from the active Stamp shape. If you give users access to
  /// the selection tool, you might want to set it as the active tool at this
  /// point.
  func stampToolDidTapAway(tappedPoint: CGPoint)

  /// The Stamp tool is about to present a Stamp editing view. You may configure
  /// it however you like. If you're just starting out, you probably want to
  /// call `editingView.addStandardControls()` to add the delete button and the
  /// two resize handles.
  func stampToolWillUseEditingView(_ editingView: StampShapeEditingView)

  /// The user has changed the transform of the selected shape. You may leave
  /// this method empty, but unless you want your Stamp controls to scale with
  /// the Stamp, you'll need to do some math and apply some inverse scaling
  /// transforms here.
  func stampToolDidUpdateEditingViewTransform(_ editingView: StampShapeEditingView, transform: ShapeTransform)
}

public class StampTool: NSObject, DrawingTool {
	
  /// MARK: Protocol requirements
  public var name: String = "Stamp"
  public let isProgressive = false
	
  // MARK: Public properties

  /// You may set yourself as the delegate to be notified when special selection
  /// events happen that you might want to react to. The core framework does
  /// not use this delegate.
  public weak var delegate: StampToolDelegate?
  private var imageName: String = ""
  private var originalImageName: String = ""

  // MARK: Internal state

  /// The Stamp tool has 3 different behaviors on drag depending on where your
  /// touch starts. See `DragHandler.swift` for their implementations.
  private var dragHandler: StampDragHandler?
  private var selectedShape: StampShape?
  private weak var shapeUpdater: DrawsanaViewShapeUpdating?
  // internal for use by DragHandler subclasses
  internal lazy var editingView: StampShapeEditingView = makeStampView()

  public init(delegate: StampToolDelegate? = nil) {
    super.init()
    self.delegate = delegate
  }

  // MARK: Tool lifecycle

  public func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?) {
    self.shapeUpdater = shapeUpdater
    if let shape = shape as? StampShape {
      beginEditing(shape: shape, context: context)
    }
  }

  public func deactivate(context: ToolOperationContext) {
    context.toolSettings.interactiveView = nil
    context.toolSettings.selectedShape = nil
    finishEditing(context: context)
    selectedShape = nil
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    if let shapeInProgress = self.selectedShape {
      handleTapWhenShapeIsActive(context: context, point: point, shape: shapeInProgress)
    } else {
      handleTapWhenNoShapeIsActive(context: context, point: point)
    }
  }

  private func handleTapWhenShapeIsActive(context: ToolOperationContext, point: CGPoint, shape: StampShape) {
    if let dragActionType = editingView.getDragActionType(point: point), case .delete = dragActionType {
      applyRemoveShapeOperation(context: context)
      delegate?.stampToolDidTapAway(tappedPoint: point)
    } else if shape.hitTest(point: point) {
      // TODO: Forward tap to editingView.textView somehow, or manually set
      // the cursor point
    } else {
      finishEditing(context: context)
      selectedShape = nil
      delegate?.stampToolDidTapAway(tappedPoint: point)
    }
    return
  }

  private func handleTapWhenNoShapeIsActive(context: ToolOperationContext, point: CGPoint) {
    if let tappedShape = context.drawing.getShape(of: StampShape.self, at: point) {
      beginEditing(shape: tappedShape, context: context)
      context.toolSettings.isPersistentBufferDirty = true
    } else {
      let newShape = StampShape()
      newShape.apply(userSettings: context.userSettings)
		newShape.boundingRect = CGRect(origin: point, size: CGSize(width: 100, height: 100))
		self.selectedShape = newShape
      newShape.transform.translation = delegate?.stampToolPointForNewStamp(tappedPoint: point) ?? point
      beginEditing(shape: newShape, context: context)
      context.operationStack.apply(operation: AddShapeOperation(shape: newShape))
    }
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shape = selectedShape else { return }
    if let dragActionType = editingView.getDragActionType(point: point), case .resizeAndRotate = dragActionType {
      dragHandler = StampResizeAndRotateHandler(shape: shape, stampTool: self)
    } else if shape.hitTest(point: point) {
      dragHandler = StampMoveHandler(shape: shape, stampTool: self)
    } else {
      dragHandler = nil
    }

    if let dragHandler = dragHandler {
	  applyEditStampOperationIfStampHasChanged(context: context)
      dragHandler.handleDragStart(context: context, point: point)
    }
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    if let dragHandler = dragHandler {
      dragHandler.handleDragContinue(context: context, point: point, velocity: velocity)
    } else {
      // The pan gesture is super finicky at the start, so add an affordance for
      // dragging over a handle
      switch editingView.getDragActionType(point: point) {
      case .some(.resizeAndRotate), .some(.changeImage):
        handleDragStart(context: context, point: point)
      default: break
      }
    }
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    if let dragHandler = dragHandler {
      dragHandler.handleDragEnd(context: context, point: point)
      self.dragHandler = nil
    }
    context.toolSettings.isPersistentBufferDirty = true
    updateImageView()
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    if let dragHandler = dragHandler {
      dragHandler.handleDragCancel(context: context, point: point)
      self.dragHandler = nil
    }
  }

  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    selectedShape?.apply(userSettings: userSettings)
    updateImageView()
    if context.toolSettings.selectedShape == nil {
      selectedShape = nil
      context.toolSettings.interactiveView = nil
    }
    context.toolSettings.isPersistentBufferDirty = true
  }

  // MARK: Helpers: begin/end editing actions

  private func beginEditing(shape: StampShape, context: ToolOperationContext) {
    // Remember values
    //originalImageName = shape.imageName
	
    // Configure and re-render shape for editing
    shape.isBeingEdited = true // stop rendering this shape while textView is open
    shapeUpdater?.rerenderAllShapesInefficiently()

    // Set selection in an order that guarantees the *initial* selection rect
    // is correct
    selectedShape = shape
    updateShapeFrame()
    context.toolSettings.selectedShape = shape

    // Prepare interactive editing view
    context.toolSettings.interactiveView = editingView
  }

  /// If shape text has changed, notify operation stack so that undo works
  /// properly
  private func finishEditing(context: ToolOperationContext) {
    applyEditStampOperationIfStampHasChanged(context: context)
    selectedShape?.isBeingEdited = false
    context.toolSettings.interactiveView = nil
    context.toolSettings.isPersistentBufferDirty = true
  }

  private func applyEditStampOperationIfStampHasChanged(context: ToolOperationContext) {
    guard let shape = selectedShape, originalImageName != shape.imageName else { return }
    context.operationStack.apply(operation: EditStampOperation(
      shape: shape,
      originalImageName: originalImageName,
      imageName: shape.imageName))
    originalImageName = shape.imageName
  }
  private func applyRemoveShapeOperation(context: ToolOperationContext) {
    guard let shape = selectedShape else { return }
    shape.isBeingEdited = false
    context.operationStack.apply(operation: RemoveShapeOperation(shape: shape))
    selectedShape = nil
    context.toolSettings.selectedShape = nil
    context.toolSettings.isPersistentBufferDirty = true
    context.toolSettings.interactiveView = nil
  }

  // MARK: Other helpers

  func updateShapeFrame() {
    guard let shape = selectedShape else { return }
    // Shape jumps a little after editing unless we add this fudge factor
    shape.boundingRect.origin.x += 2
    updateImageView()
  }

  func updateImageView() {
    guard let shape = selectedShape else { return }
    editingView.transform = CGAffineTransform(
      translationX: -shape.boundingRect.size.width / 2,
      y: -shape.boundingRect.size.height / 2
    ).concatenating(shape.transform.affineTransform)

    editingView.setNeedsLayout()
    editingView.layoutIfNeeded()
  }
  private func makeStampView() -> StampShapeEditingView {
    let imageView = UIImageView()
    imageView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
	imageView.contentMode = .scaleAspectFit
	imageView.clipsToBounds = true
    imageView.backgroundColor = .clear
    let editingView = StampShapeEditingView(imageView: imageView)
    if let delegate = delegate {
      delegate.stampToolWillUseEditingView(editingView)
    } else {
      editingView.addStandardControls()
    }
    return editingView
  }
}
