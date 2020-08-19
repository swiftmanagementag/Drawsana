//
//  StarTool_PentagonTool_TriangleTool.swift
//  Drawsana
//
//  Created by Madan Gupta on 31/12/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import Foundation

public class StarTool: DrawingToolForShapeWithTwoPoints {
    override public var name: String { return "Star" }
    override public func makeShape() -> ShapeType { return StarShape() }
}

public class PentagonTool: DrawingToolForShapeWithTwoPoints {
    override public var name: String { return "Pentagon" }
    override public func makeShape() -> ShapeType { return NgonShape(5) }
}

public class TriangleTool: DrawingToolForShapeWithTwoPoints {
    override public var name: String { return "Triangle" }
    override public func makeShape() -> ShapeType { return NgonShape(3) }
}
