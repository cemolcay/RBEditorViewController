//
//  RBRhythmToolbarMode.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class RhythmToolbarModeProps: RBToolbarModeProps {
  var rhythmData: RBRhythmData?
  var didAddRhythmCallback: ((RBRhythmData) -> Void)?
  var didUpdateRhythmCallback: ((RBRhythmData) -> Void)?

  required init() {}

  init(
    rhythmData: RBRhythmData?,
    didAddRhythmCallback: ((RBRhythmData) -> Void)?,
    didUpdateRhythmCallback: ((RBRhythmData) -> Void)?) {
    self.rhythmData = rhythmData
    self.didAddRhythmCallback = didAddRhythmCallback
    self.didUpdateRhythmCallback = didUpdateRhythmCallback
  }
}

class RhythmToolbarModeView: RBToolbarModeView<RhythmToolbarModeProps> {
  let durationStack = UIStackView()
  let modifierSegment = UISegmentedControl()

  override func render() {
    super.render()
    durationStack.spacing = 8
    stackView.addArrangedSubview(durationStack)
    stackView.addArrangedSubview(modifierSegment)

    RBDurationType.allCases
      .map({ $0.toolbarButton() })
      .forEach({
        $0.addTarget(self, action: #selector(didEditCell(sender:)), for: .touchUpInside)
        durationStack.addArrangedSubview($0)
      })

    modifierSegment.removeAllSegments()
    RBModifierType.allCases
      .map({ $0.description })
      .enumerated()
      .forEach({ modifierSegment.insertSegment(withTitle: $0.element, at: $0.offset, animated: false) })
    modifierSegment.selectedSegmentIndex = 0
  }

  @IBAction func didEditCell(sender: UIButton) {
    guard let durationType = RBDurationType(rawValue: sender.tag),
      let modifierType = RBModifierType(rawValue: modifierSegment.selectedSegmentIndex)
      else { return }
    let value = durationType.value * modifierType.value

    // Edit selected cell
    if let data = props.rhythmData {
      data.duration = value
      props.didUpdateRhythmCallback?(data)
    } else { // Add Cell
      let data = RBRhythmData(duration: value)
      props.didAddRhythmCallback?(data)
    }
  }
}

final class RhythmToolbarMode: RBToolbarMode {
  typealias PropType = RhythmToolbarModeProps
  var props = RhythmToolbarModeProps()
  var toolbarTitle: String = "Add Rhythm"

  var view: RBToolbarModeView<RhythmToolbarModeProps> {
    return RhythmToolbarModeView(props: props)
  }
}
