//
//  RBData.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class RBHistory {
  private var dataRef: RBPatternData
  private(set) var stack: [[RBRhythmData]]
  private(set) var cursor: Int
  var limit: Int = 20

  var canUndo: Bool {
    return cursor > 0
  }

  var canRedo: Bool {
    return cursor < stack.count - 1
  }

  init(dataRef: RBPatternData) {
    self.dataRef = dataRef
    self.stack = []
    self.cursor = 0
  }

  func push() {
    let snap = dataRef.cells.map({ $0.copy() }).compactMap({ $0 as? RBRhythmData })
    stack = Array((Array(stack.prefix(cursor + 1)) + [snap]).suffix(limit))
    cursor = stack.count - 1
  }

  func undo() -> [RBRhythmData]? {
    guard canUndo else { return nil }
    cursor -= 1
    return stack[cursor]
  }

  func redo() -> [RBRhythmData]? {
    guard canRedo else { return nil }
    cursor += 1
    return stack[cursor]
  }
}

enum RBMode: Int, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case rhythm
  case arp
  case ratchet
  case velocity
  case snapshots

  var description: String {
    switch self {
    case .rhythm: return "Rtm"
    case .arp: return "Arp"
    case .ratchet: return "Rat"
    case .velocity: return "Vel"
    case .snapshots: return "Snap"
    }
  }
}

enum RBAction: Int, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case play
  case record
  case clear
  case quantize

  var description: String {
    switch self {
    case .play: return "Play"
    case .record: return "Record"
    case .clear: return "Clear"
    case .quantize: return "Quantize"
    }
  }
}

enum RBDurationType: Int, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case doubleWhole
  case whole
  case half
  case quarter
  case eighth
  case sixteenth
  case thirtysecond
  case sixthfourth

  var value: Double {
    switch self {
    case .doubleWhole: return 2.0
    case .whole: return 1.0
    case .half: return 1.0 / 2.0
    case .quarter: return 1.0 / 4.0
    case .eighth: return 1.0 / 8.0
    case .sixteenth: return 1.0 / 16.0
    case .thirtysecond: return 1.0 / 32.0
    case .sixthfourth: return 1.0 / 64.0
    }
  }

  var description: String {
    switch self {
    case .doubleWhole: return "2"
    case .whole: return "1"
    case .half: return "1/2"
    case .quarter: return "1/4"
    case .eighth: return "1/8"
    case .sixteenth: return "1/16"
    case .thirtysecond: return "1/32"
    case .sixthfourth: return "1/64"
    }
  }
}

enum RBModifierType: Int, CaseIterable, CustomStringConvertible {
  case none
  case dotted
  case triplet
  case quintuplet

  var value: Double {
    switch self {
    case .none: return 1
    case .dotted: return 1.5
    case .triplet: return 1.63
    case .quintuplet: return 1.4
    }
  }

  var description: String {
    switch self {
      case .none: return "None"
      case .dotted: return "Dot"
      case .triplet: return "Trip"
      case .quintuplet: return "Quint"
    }
  }
}

enum RBArp: Int, Codable, Equatable, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case none
  case up
  case down
  case updown
  case random
  case highFirst
  case lowFirst

  var description: String {
    switch self {
    case .none: return "None"
    case .up: return "Up"
    case .down: return "Down"
    case .updown: return "Up-Down"
    case .random: return "Random"
    case .highFirst: return "High First"
    case .lowFirst: return "Low First"
    }
  }
}

enum RBRatchet: Int, Codable, Equatable, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case none
  case two
  case three
  case four

  var description: String {
    switch self {
    case .none: return "None"
    case .two: return "2"
    case .three: return "3"
    case .four: return "4"
    }
  }
}

class RBRhythmData: Codable, Equatable, NSCopying {
  var id: String
  var position: Double
  var duration: Double
  var velocity: Int
  var arp: RBArp
  var ratchet: RBRatchet

  enum CodingKeys: CodingKey {
    case id
    case position
    case duration
    case velocity
    case arp
    case ratchet
  }

  init(
    id: String? = nil,
    position: Double = 0,
    duration: Double = 0,
    velocity: Int = 90,
    arp: RBArp = .none,
    ratchet: RBRatchet = .none) {
    self.id = id ?? UUID().uuidString
    self.position = position
    self.duration = duration
    self.velocity = velocity
    self.arp = arp
    self.ratchet = ratchet
  }

  // MARK: Codable

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    position = try values.decode(Double.self, forKey: .position)
    duration = try values.decode(Double.self, forKey: .duration)
    velocity = try values.decode(Int.self, forKey: .velocity)
    arp = try values.decode(RBArp.self, forKey: .arp)
    ratchet = try values.decode(RBRatchet.self, forKey: .ratchet)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(position, forKey: .position)
    try container.encode(duration, forKey: .duration)
    try container.encode(velocity, forKey: .velocity)
    try container.encode(arp, forKey: .arp)
    try container.encode(ratchet, forKey: .ratchet)
  }

  // MARK: NSCopynig

  func copy(with zone: NSZone? = nil) -> Any {
    return RBRhythmData(
      position: position,
      duration: duration,
      velocity: velocity,
      arp: arp,
      ratchet: ratchet)
  }

  // MARK: Equatable

  static func == (lhs: RBRhythmData, rhs: RBRhythmData) -> Bool {
    return lhs.position == rhs.position &&
      lhs.duration == rhs.duration &&
      lhs.velocity == rhs.velocity &&
      lhs.arp == rhs.arp &&
      lhs.ratchet == rhs.ratchet
  }
}

class RBSnapshotData: Codable {
  var id: String
  var cells: [[RBRhythmData]]
  var cc: Int

  enum CodingKeys: CodingKey {
    case id
    case cells
    case cc
  }

  init(id: String? = nil, cells: [[RBRhythmData]] = [], cc: Int = 0) {
    self.id = id ?? UUID().uuidString
    self.cells = cells
    self.cc = cc
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    cells = try values.decode([[RBRhythmData]].self, forKey: .cells)
    cc = try values.decode(Int.self, forKey: .cc)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(cells, forKey: .cells)
    try container.encode(cc, forKey: .cc)
  }
}

class RBPatternData: Codable {
  var id: String
  var cells: [RBRhythmData]
  var snapshots: RBSnapshotData

  enum CodingKeys: CodingKey {
    case id
    case cells
    case snapshots
  }

  init(
    id: String? = nil,
    cells: [RBRhythmData] = [],
    snapshots: RBSnapshotData = RBSnapshotData()) {
    self.id = id ?? UUID().uuidString
    self.cells = cells
    self.snapshots = snapshots
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    cells = try values.decode([RBRhythmData].self, forKey: .cells)
    snapshots = try values.decode(RBSnapshotData.self, forKey: .snapshots)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(cells, forKey: .cells)
    try container.encode(snapshots, forKey: .snapshots)
  }

  func snapshot() {
    let snap = cells.map({ $0.copy() }).compactMap({ $0 as? RBRhythmData })
    snapshots.cells.append(snap)
  }
}
