//
//  RBData.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

struct TimeSignature: Codable {
  var beats: Int = 4
}

struct Tempo: Codable {
  var timeSignature: TimeSignature = TimeSignature()
  var bpm: Double = 120
}

struct RBHistoryItem: Equatable {
  let rhythmData: [RBRhythmData]
  let duration: Double
}

extension Collection {
  /// Returns the element at the specified index iff it is within bounds, otherwise nil.
  subscript(safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

extension UIImage {
  func scaleImage(to size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
    draw(in: CGRect(origin: .zero, size: size))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}

extension Collection where Element == RBRhythmData {
  func copy() -> [RBRhythmData] {
    return map({ $0.copy() as? RBRhythmData }).compactMap({ $0 })
  }
}

extension UIColor {
  static let toolbarButtonSelectedBackgroundColor = UIColor(red: 133.0/255.0, green: 133.0/255.0, blue: 133.0/255.0, alpha: 1)
  static let toolbarButtonBackgroundColor = UIColor.clear
  static let toolbarButtonTextColor = UIColor.white
  static let toolbarButtonSelectedTextColor = UIColor.white
  static let toolbarBackgroundColor = UIColor(red: 84.0/255.0, green: 84.0/255.0, blue: 84.0/255.0, alpha: 1)
  static let toolbarBorderColor = UIColor.black
  static let toolbarTitleColor = UIColor.white
  static let actionBarTitleColor = UIColor.white
  static let actionBarBackgroundColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1)
  static let actionBarBorderColor = UIColor.black
  static let gridBackgroundColor = UIColor(red: 46.0/255.0, green: 46.0/255.0, blue: 46.0/255.0, alpha: 1)
  static let gridLineColor = UIColor(red: 92.0/255.0, green: 92.0/255.0, blue: 92.0/255.0, alpha: 1)
  static let measureBackgroundColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1)
  static let measureLineColor = UIColor(red: 110.0/255.0, green: 110.0/255.0, blue: 110.0/255.0, alpha: 1)
  static let measureTextColor = UIColor.white
  static let playheadBackgroundColor = UIColor(red: 176.0/255.0, green: 176.0/255.0, blue: 176.0/255.0, alpha: 1)
  static let playheadBorderColor = UIColor.white
  static let rangeheadBackgroundColor = UIColor(red: 176.0/255.0, green: 176.0/255.0, blue: 176.0/255.0, alpha: 1)
  static let rangeheadBorderColor = UIColor.white
  static let rhythmCellBackgroundColor = UIColor(red: 49.0/255.0, green: 88.0/255.0, blue: 130.0/255.0, alpha: 1)
  static let rhythmCellSelectedBorderColor = UIColor(red: 201.0/255.0, green: 227.0/255.0, blue: 255.0/255.0, alpha: 1)
  static let rhythmCellBorderColor = UIColor.black
  static let segmentedControlTextColor = UIColor.white
  static let segmentedControlSelectedTextColor = UIColor.black
}

extension UIFont {
  static let actionBarTitleFont = UIFont.systemFont(ofSize: 17, weight: .medium)
  static let toolbarTitleFont = UIFont.systemFont(ofSize: 15, weight: .medium)
  static let toolbarButtonFont = UIFont.systemFont(ofSize: 13)
  static let toolbarButtonSelectedFont = UIFont.systemFont(ofSize: 13)
}

extension UIViewController {
  func setupRhythmBudTheme() {
    view.backgroundColor = UIColor.gridBackgroundColor
    navigationController?.navigationBar.barTintColor = .darkGray
    navigationController?.navigationBar.tintColor = .white
    navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
  }
}

class RBHistory {
  private var dataRef: RBProjectData
  private(set) var stack: [RBHistoryItem]
  private(set) var cursor: Int { didSet { historyDidChangeCallback?() }}
  var limit: Int = 20
  var historyDidChangeCallback: (() -> Void)?

  var canUndo: Bool {
    return cursor > 0
  }

  var canRedo: Bool {
    return cursor < stack.count - 1
  }

  init(dataRef: RBProjectData) {
    self.dataRef = dataRef
    self.stack = []
    self.cursor = 0
  }

  func push() {
    let historyItem = RBHistoryItem(
      rhythmData: dataRef.rhythm.copy(),
      duration: dataRef.duration)
    stack = Array((Array(stack.prefix(cursor + 1)) + [historyItem]).suffix(limit))
    cursor = stack.count - 1
  }

  func undo() -> RBHistoryItem? {
    guard canUndo else { return nil }
    cursor -= 1
    return stack[cursor]
  }

  func redo() -> RBHistoryItem? {
    guard canRedo else { return nil }
    cursor += 1
    return stack[cursor]
  }
}

enum RBMode: Int, Codable, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case record
  case rhythm
  case arp
  case ratchet
  case velocity
  case transpose
  case snapshots

  var description: String {
    switch self {
    case .record: return i18n.record.description
    case .rhythm: return i18n.rhythm.description
    case .arp: return i18n.arp.description
    case .ratchet: return i18n.ratchet.description
    case .velocity: return i18n.velocity.description
    case .transpose: return i18n.transpose.description
    case .snapshots: return i18n.snapshots.description
    }
  }
}

enum RBAction: Int, Codable, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case clear
  case quantize
  case undo
  case redo

  var description: String {
    switch self {
    case .clear: return i18n.clear.description
    case .quantize: return i18n.quantize.description
    case .undo: return i18n.undo.description
    case .redo: return i18n.redo.description
    }
  }

  var image: UIImage? {
    switch self {
    case .clear: return UIImage(named: "bin2")
    case .quantize: return UIImage(named: "beat")
    case .undo: return UIImage(named: "undo")
    case .redo: return UIImage(named: "redo")
    }
  }

  var actionButton: UIButton {
    let button = UIButton(frame: .zero)
    button.tag = rawValue
    button.setImage(self.image, for: .normal)
    button.tintColor = UIColor.toolbarButtonTextColor
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1).isActive = true
    return button
  }
}

enum RBDurationType: Int, Codable, CaseIterable, CustomStringConvertible, ToolbarButtoning {
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
    case .eighth: return "8th"
    case .sixteenth: return "16th"
    case .thirtysecond: return "32nd"
    case .sixthfourth: return "64th"
    }
  }
}

enum RBRhythmType: Int, Codable, CaseIterable, CustomStringConvertible {
  case note
  case rest

  var description: String {
    switch self {
    case .note: return i18n.note.description
    case .rest: return i18n.rest.description
    }
  }

  var image: UIImage? {
    switch self {
    case .note: return UIImage(named: "notesIcon")
    case .rest: return UIImage(named: "restIcon")
    }
  }
}

enum RBModifierType: Int, Codable, CaseIterable, CustomStringConvertible {
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
    case .none: return i18n.none.description
    case .dotted: return i18n.dotted.description
    case .triplet: return i18n.triplet.description
    case .quintuplet: return i18n.quintuplet.description
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
    case .none: return i18n.none.description
    case .up: return i18n.upOrder.description
    case .down: return i18n.downOrder.description
    case .updown: return i18n.upDownOrder.description
    case .random: return i18n.randomOrder.description
    case .highFirst: return i18n.highFirstOrder.description
    case .lowFirst: return i18n.lowFirstOrder.description
    }
  }
}

enum RBRatchet: Int, Codable, Equatable, CaseIterable, CustomStringConvertible, ToolbarButtoning {
  case none
  case two
  case three
  case four

  var count: Int {
    switch self {
    case .none: return 1
    case .two: return 2
    case .three: return 3
    case .four: return 4
    }
  }

  var description: String {
    switch self {
    case .none: return i18n.none.description
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
  var transpose: Int
  var arp: RBArp
  var ratchet: RBRatchet

  enum CodingKeys: CodingKey {
    case id
    case position
    case duration
    case velocity
    case transpose
    case arp
    case ratchet
  }

  init(
    id: String? = nil,
    position: Double = 0,
    duration: Double = 0,
    velocity: Int = 90,
    tranpose: Int = 0,
    arp: RBArp = .none,
    ratchet: RBRatchet = .none) {
    self.id = id ?? UUID().uuidString
    self.position = position
    self.duration = duration
    self.velocity = velocity
    self.transpose = tranpose
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
    transpose = try values.decode(Int.self, forKey: .transpose)
    arp = try values.decode(RBArp.self, forKey: .arp)
    ratchet = try values.decode(RBRatchet.self, forKey: .ratchet)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(position, forKey: .position)
    try container.encode(duration, forKey: .duration)
    try container.encode(velocity, forKey: .velocity)
    try container.encode(transpose, forKey: .transpose)
    try container.encode(arp, forKey: .arp)
    try container.encode(ratchet, forKey: .ratchet)
  }

  // MARK: NSCopynig

  func copy(with zone: NSZone? = nil) -> Any {
    return RBRhythmData(
      position: position,
      duration: duration,
      velocity: velocity,
      tranpose: transpose,
      arp: arp,
      ratchet: ratchet)
  }

  // MARK: Equatable

  static func == (lhs: RBRhythmData, rhs: RBRhythmData) -> Bool {
    return lhs.position == rhs.position &&
      lhs.duration == rhs.duration &&
      lhs.velocity == rhs.velocity &&
      lhs.transpose == rhs.transpose &&
      lhs.arp == rhs.arp &&
      lhs.ratchet == rhs.ratchet
  }
}

struct RBSnapshotItem: Codable {
  let rhythmData: [RBRhythmData]
  let duration: Double

  func copy() -> RBSnapshotItem {
    return RBSnapshotItem(
      rhythmData: rhythmData.copy(),
      duration: duration)
  }
}

class RBSnapshotData: Codable, NSCopying {
  var id: String
  var cc: Int
  var snapshots: [RBSnapshotItem]

  enum CodingKeys: CodingKey {
    case id
    case cc
    case snapshots
  }

  init(id: String? = nil, cc: Int = 0, snapshots: [RBSnapshotItem] = []) {
    self.id = id ?? UUID().uuidString
    self.cc = cc
    self.snapshots = snapshots
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    cc = try values.decode(Int.self, forKey: .cc)
    snapshots = try values.decode([RBSnapshotItem].self, forKey: .snapshots)
  }

  // MARK: Encodable

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(cc, forKey: .cc)
    try container.encode(snapshots, forKey: .snapshots)
  }

  // MARK: NSCopying

  func copy(with zone: NSZone? = nil) -> Any {
    return RBSnapshotData(
      id: id,
      cc: cc,
      snapshots: snapshots.map({ $0.copy() }))
  }
}

class RBProjectData: Codable, NSCopying {
  var id: String
  var name: String
  var rhythm: [RBRhythmData]
  var tempo: Tempo
  var duration: Double
  var snapshotData: RBSnapshotData
  var createDate: Date

  enum CodingKeys: CodingKey {
    case id
    case name
    case rhythm
    case tempo
    case duration
    case snapshotData
    case createDate
  }

  init(
    id: String? = nil,
    name: String,
    rhythm: [RBRhythmData] = [],
    tempo: Tempo = Tempo(),
    duration: Double = 0,
    snapshotData: RBSnapshotData = RBSnapshotData(),
    creationDate: Date = Date()) {
    self.id = id ?? UUID().uuidString
    self.name = name
    self.rhythm = rhythm
    self.duration = duration
    self.tempo = tempo
    self.snapshotData = snapshotData
    self.createDate = creationDate
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    name = try values.decode(String.self, forKey: .name)
    rhythm = try values.decode([RBRhythmData].self, forKey: .rhythm)
    duration = try values.decode(Double.self, forKey: .duration)
    tempo = try values.decode(Tempo.self, forKey: .tempo)
    snapshotData = try values.decode(RBSnapshotData.self, forKey: .snapshotData)
    createDate = try values.decode(Date.self, forKey: .createDate)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(rhythm, forKey: .rhythm)
    try container.encode(duration, forKey: .duration)
    try container.encode(tempo, forKey: .tempo)
    try container.encode(snapshotData, forKey: .snapshotData)
    try container.encode(createDate, forKey: .createDate)
  }

  func snapshot() {
    let snapshotItem = RBSnapshotItem(
      rhythmData: rhythm.copy(),
      duration: duration)
    snapshotData.snapshots.append(snapshotItem)
  }

  func copy(with zone: NSZone? = nil) -> Any {
    return RBProjectData(
      id: id,
      name: name,
      rhythm: rhythm.copy(),
      tempo: tempo,
      duration: duration,
      snapshotData: snapshotData.copy() as? RBSnapshotData ?? RBSnapshotData(),
      creationDate: createDate)
  }
}
