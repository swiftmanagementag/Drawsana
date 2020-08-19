//
//  TextShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/3/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public class TextShape: Shape, ShapeSelectable {
    private enum CodingKeys: String, CodingKey {
        case id, transform, text, fontName, fontSize, fillColor, type, explicitWidth, boundingRect
    }

    public static let type = "Text"

    public var id: String = UUID().uuidString
    /// This shape is positioned entirely with `TextShape.transform.translate`,
    /// rather than storing an explicit position.
    public var transform: ShapeTransform = .identity
    public var text = ""
    public var fontName: String = "Helvetica Neue"
    public var fontSize: CGFloat = 24
    public var fillColor: UIColor = .black
    /// If user drags the text box to an exact width, we need to respect it instead
    /// of automatically sizing the text box to fit the text.
    public var explicitWidth: CGFloat?

    /// Set to true if this text is being shown in some other way, i.e. in a
    /// `UITextView` that the user is editing.
    public var isBeingEdited: Bool = false

    public var boundingRect: CGRect = .zero

    var font: UIFont {
        return UIFont(name: fontName, size: fontSize)!
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let type = try values.decode(String.self, forKey: .type)
        if type != TextShape.type {
            throw DrawsanaDecodingError.wrongShapeTypeError
        }

        id = try values.decode(String.self, forKey: .id)
        text = try values.decode(String.self, forKey: .text)
        fontName = try values.decode(String.self, forKey: .fontName)
        fontSize = try values.decode(CGFloat.self, forKey: .fontSize)
        fillColor = UIColor(hexString: try values.decode(String.self, forKey: .fillColor))
        boundingRect = try values.decode(CGRect.self, forKey: .boundingRect)
        explicitWidth = try values.decodeIfPresent(CGFloat.self, forKey: .explicitWidth)
        transform = try values.decode(ShapeTransform.self, forKey: .transform)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(TextShape.type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(fontName, forKey: .fontName)
        try container.encode(fillColor.hexString, forKey: .fillColor)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(boundingRect, forKey: .boundingRect)
        try container.encodeIfPresent(explicitWidth, forKey: .explicitWidth)
        try container.encode(transform, forKey: .transform)
    }

    public func render(in context: CGContext) {
        if isBeingEdited { return }
        transform.begin(context: context)
        (text as NSString).draw(
            in: CGRect(origin: boundingRect.origin, size: boundingRect.size),
            withAttributes: [
                .font: font,
                .foregroundColor: fillColor,
            ]
        )
        transform.end(context: context)
    }

    public func resize(by factor: CGFloat, offset: CGFloat) {
        if let e = explicitWidth {
            explicitWidth = e * factor
        }

        transform.scale = transform.scale * factor
        transform.translation.x = transform.translation.x * factor
        transform.translation.y = transform.translation.y * factor - offset
    }

    public func apply(userSettings: UserSettings) {
        fillColor = userSettings.strokeColor ?? .black
        fontName = userSettings.fontName
        fontSize = userSettings.fontSize
    }
}
