//
//  i18n.swift
//  ScaleBud
//
//  Created by Cem Olcay on 3.07.2018.
//  Copyright © 2018 cemolcay. All rights reserved.
//

import UIKit

enum i18n: String, CustomStringConvertible {
  case snapshots
  case mode
  case quantize
  case selectQuantizeLevel
  case addRhythm
  case editRhythm
  case editArp
  case editRatchet
  case editVelocity
  case recording
  case tapToRecord
  case recordRhythm
  case transpose
  case record
  case rhythm
  case arp
  case strum
  case strumToolbarTitle
  case offset
  case strumOrder
  case ratchet
  case clear
  case undo
  case note
  case `default`
  case highFirstOrder
  case lowFirstOrder
  case lowToHigh
  case highToLow
  case none
  case snapRangehead
  case selectSnapPosition
  case rest
  case redo
  case add
  case end
  case global
  case selectCell
  case notes
  case chords
  case scaleTypes
  case velocity
  case edit
  case delete
  case projectName
  case doubleWholeNote
  case wholeNote
  case halfNote
  case quarterNote
  case eighthNote
  case sixteenthNote
  case thirtysecondNote
  case sixtyfourthNote
  case dotted
  case triplet
  case quintuplet
  case upOrder
  case downOrder
  case upDownOrder
  case randomOrder
  case arpeggiator
  case arpeggio
  case snapshotMIDICCSettingsTitle

  var description: String {
    return NSLocalizedString(rawValue, comment: "")
  }
}
