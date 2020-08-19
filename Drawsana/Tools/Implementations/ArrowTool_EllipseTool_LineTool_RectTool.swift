//
//  AMDrawingTool+TwoPointShapes.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class LineTool: DrawingToolForShapeWithTwoPoints {
    override public var name: String { return "Line" }
    override public func makeShape() -> ShapeType { return LineShape() }
}

public class ArrowTool: DrawingToolForShapeWithTwoPoints {
    override public var name: String { return "Arrow" }
    override public func makeShape() -> ShapeType {
        let shape = LineShape()
        shape.arrowStyle = .standard
        return shape
    }
}

public class RectTool: DrawingToolForShapeWithTwoPoints {
    override public var name: String { return "Rectangle" }
    override public func makeShape() -> ShapeType { return RectShape() }
}

public class EllipseTool: DrawingToolForShapeWithTwoPoints {
    override public var name: String { return "Ellipse" }
    override public func makeShape() -> ShapeType { return EllipseShape() }
}
