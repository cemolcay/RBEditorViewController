//
//  RBToolbarButton.swift
//  RhythmBud
//
//  Created by cem.olcay on 29/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

protocol ToolbarButtoning: RawRepresentable, CustomStringConvertible {}

extension ToolbarButtoning where Self: RawRepresentable, Self.RawValue == Int  {
  func toolbarButton() -> UIButton {
    let but = UIButton(type: .system)
    but.setTitle(description, for: .normal)
    but.titleLabel?.font = UIFont.toolbarButtonFont
    but.setTitleColor(UIColor.toolbarButtonTextColor, for: .normal)
    but.setTitleColor(UIColor.toolbarButtonSelectedTextColor, for: .selected)
    but.tintColor = UIColor.toolbarButtonSelectedBackgroundColor
    but.backgroundColor = UIColor.toolbarButtonBackgroundColor
    but.tag = rawValue
    return but
  }
}
