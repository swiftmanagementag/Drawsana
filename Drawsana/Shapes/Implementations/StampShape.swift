//
//  StampShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/3/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit
import Drawsana

public class StampShape: Shape, ShapeSelectable {
  private enum CodingKeys: String, CodingKey {
    case id, transform, imageName, type, boundingRect
  }

  public static let type = "Stamp"

  public var id: String = UUID().uuidString
  /// This shape is positioned entirely with `StamptShape.transform.translate`,
  public var transform: ShapeTransform = .identity
  public var imageName = "car_1.png"

  /// Set to true if this text is being shown in some other way, i.e. in a
  public var isBeingEdited: Bool = false

  public var boundingRect: CGRect = .zero

  public init() {
  }

  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    let type = try values.decode(String.self, forKey: .type)
    if type != StampShape.type {
      throw DrawsanaDecodingError.wrongShapeTypeError
    }

    id = try values.decode(String.self, forKey: .id)
    imageName = try values.decode(String.self, forKey: .imageName)
	boundingRect = try values.decode(CGRect.self, forKey: .boundingRect)
    transform = try values.decode(ShapeTransform.self, forKey: .transform)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(StampShape.type, forKey: .type)
    try container.encode(id, forKey: .id)
    try container.encode(imageName, forKey: .imageName)
	try container.encode(boundingRect, forKey: .boundingRect)
	try container.encode(transform, forKey: .transform)
  }

  public func render(in context: CGContext) {
    if isBeingEdited { return }
    transform.begin(context: context)
	if let image = UIImage(named: self.imageName) {
		image.draw(
			in: CGRect(origin: CGPoint.zero, size: self.boundingRect.size),
			blendMode: .normal,
			alpha: 1.0
		)
	}
    transform.end(context: context)
  }

  public func apply(userSettings: UserSettings) {
  }
}
