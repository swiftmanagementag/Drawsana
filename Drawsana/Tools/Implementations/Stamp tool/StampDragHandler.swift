//
//  DragHandler.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import Drawsana

class StampDragHandler {
  let shape: StampShape
  weak var stampTool: StampTool?
  var startPoint: CGPoint = .zero

  init(
    shape: StampShape,
    stampTool: StampTool)
  {
    self.shape = shape
    self.stampTool = stampTool
  }

  func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    startPoint = point
  }

  func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {

  }

  func handleDragEnd(context: ToolOperationContext, point: CGPoint) {

  }

  func handleDragCancel(context: ToolOperationContext, point: CGPoint) {

  }
}

/// User is dragging the text itself to a new location
class StampMoveHandler: StampDragHandler {
  private var originalTransform: ShapeTransform

  override init(
    shape: StampShape,
    stampTool: StampTool)
  {
    self.originalTransform = shape.transform
    super.init(shape: shape, stampTool: stampTool)
  }

  override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
	let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
	shape.transform = originalTransform.translated(by: delta)
    stampTool?.updateImageView()
  }

  override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    context.operationStack.apply(operation: ChangeTransformOperation(
      shape: shape,
      transform: originalTransform.translated(by: delta),
      originalTransform: originalTransform))
  }

  override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shape.transform = originalTransform
    context.toolSettings.isPersistentBufferDirty = true
    stampTool?.updateShapeFrame()
  }
}

/// User is dragging the lower-right handle to change the size and rotation
/// of the stamp box
class StampResizeAndRotateHandler: StampDragHandler {
  private var originalTransform: ShapeTransform

  override init(
    shape: StampShape,
    stampTool: StampTool)
  {
    self.originalTransform = shape.transform
    super.init(shape: shape, stampTool:stampTool)
  }

  private func getResizeAndRotateTransform(point: CGPoint) -> ShapeTransform {
	
	let originalDelta = CGPoint(x: startPoint.x - shape.transform.translation.x, y: startPoint.y - shape.transform.translation.y)
    let newDelta = CGPoint(x: point.x - shape.transform.translation.x, y: point.y - shape.transform.translation.y)
    let originalDistance = sqrt((originalDelta.x * originalDelta.x) + (originalDelta.y * originalDelta.y))
    let newDistance = sqrt((newDelta.x * newDelta.x) + (newDelta.y * newDelta.y))
    let originalAngle = atan2(originalDelta.y, originalDelta.x)
    let newAngle = atan2(newDelta.y, newDelta.x)
    let scaleChange = newDistance / originalDistance
    let angleChange = newAngle - originalAngle
    return originalTransform.scaled(by: scaleChange).rotated(by: angleChange)
  }

  override func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    shape.transform = getResizeAndRotateTransform(point: point)
    stampTool?.updateImageView()
  }

  override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    context.operationStack.apply(operation: ChangeTransformOperation(
      shape: shape,
	  transform: getResizeAndRotateTransform(point: point),
      originalTransform: originalTransform))
  }

  override func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shape.transform = originalTransform
	context.toolSettings.isPersistentBufferDirty = true
    stampTool?.updateShapeFrame()
  }
}

/**
Change the transform of a `ShapeWithTransform`. Undoing sets its transform
back to its original value.
*/
/*
struct StampRemoveShapeOperation: DrawingOperation {
	func shouldAdd(to operationStack: DrawingOperationStack) -> Bool {
		return false
	}
	
	let shape: Shape
	
	func apply(drawing: Drawing) {
		drawing.remove(shape: shape)
	}
	
	func revert(drawing: Drawing) {
		drawing.add(shape: shape)
	}
}

struct StampChangeTransformOperation: DrawingOperation {
	let shape: ShapeWithTransform
	let transform: ShapeTransform
	let originalTransform: ShapeTransform
	
	init(shape: ShapeWithTransform, transform: ShapeTransform, originalTransform: ShapeTransform) {
		self.shape = shape
		self.transform = transform
		self.originalTransform = originalTransform
	}
	
	func apply(drawing: Drawing) {
		shape.transform = transform
		drawing.update(shape: shape)
	}
	
	func revert(drawing: Drawing) {
		shape.transform = originalTransform
		drawing.update(shape: shape)
	}
	func shouldAdd(to operationStack: DrawingOperationStack) -> Bool {
		return false
	}
	
}

struct StampAddShapeOperation: DrawingOperation {
	func shouldAdd(to operationStack: DrawingOperationStack) -> Bool {
		return true
	}
	
	let shape: Shape
	
	func apply(drawing: Drawing) {
		drawing.add(shape: shape)
	}
	
	func revert(drawing: Drawing) {
		drawing.remove(shape: shape)
	}
}
*/
struct EditStampOperation: DrawingOperation {
	let shape: StampShape
	let originalImageName: String
	let imageName: String
	
	init(
		shape: StampShape,
		originalImageName: String,
		imageName: String)
	{
		self.shape = shape
		self.originalImageName = originalImageName
		self.imageName = imageName
	}
	
	func shouldAdd(to operationStack: DrawingOperationStack) -> Bool {
		if imageName.isEmpty,
			let addShapeOp = operationStack.undoStack.last as? AddShapeOperation,
			addShapeOp.shape === shape
		{
			// It's pointless to let the user undo to an empty text shape. By setting
			// the shape text immediately and then declining to be added to the stack,
			// the add-shape operation ends up adding/removing the shape with the
			// correct text on its own.
			shape.imageName = imageName
			return false
		} else {
			return true
		}
	}
	
	func apply(drawing: Drawing) {
		shape.imageName = imageName
		drawing.update(shape: shape)
	}
	
	func revert(drawing: Drawing) {
		shape.imageName = originalImageName
		drawing.update(shape: shape)
	}
}
