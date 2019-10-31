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
  var didAddRestCallback: ((Double) -> Void)?
  var didUpdateRhythmCallback: ((RBRhythmData) -> Void)?

  required init() {}

  init(
    rhythmData: RBRhythmData?,
    didAddRhythmCallback: ((RBRhythmData) -> Void)?,
    didAddRestCallback: ((Double) -> Void)?,
    didUpdateRhythmCallback: ((RBRhythmData) -> Void)?) {
    self.rhythmData = rhythmData
    self.didAddRhythmCallback = didAddRhythmCallback
    self.didAddRestCallback = didAddRestCallback
    self.didUpdateRhythmCallback = didUpdateRhythmCallback
  }
}

class RhythmToolbarModeView: RBToolbarModeView<RhythmToolbarModeProps> {
  let rhythmStack = UIStackView()
  let modifierSegment = UISegmentedControl()
  let rhythmSegment = UISegmentedControl()

  override func render() {
    super.render()

    let durationStack = UIStackView()
    durationStack.axis = .horizontal
    durationStack.spacing = 8
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
      .forEach({
        modifierSegment.insertSegment(withTitle: $0.element, at: $0.offset, animated: false)
      })
    modifierSegment.selectedSegmentIndex = 0
    rhythmSegment.removeAllSegments()

    if #available(iOS 13.0, *) {
      rhythmSegment.backgroundColor = UIColor.toolbarButtonSelectedBackgroundColor
      rhythmSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.segmentedControlSelectedTextColor], for: .selected)
      rhythmSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.segmentedControlTextColor], for: .normal)
      modifierSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.segmentedControlSelectedTextColor], for: .selected)
      modifierSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.segmentedControlTextColor], for: .normal)
      modifierSegment.backgroundColor = UIColor.toolbarButtonSelectedBackgroundColor
    } else {
      rhythmSegment.tintColor = UIColor.white
      modifierSegment.tintColor = UIColor.white
    }

    RBRhythmType.allCases
      .map({ $0.image?.scaleImage(to: CGSize(width: 20, height: 20)) })
      .enumerated()
      .forEach({
        rhythmSegment.insertSegment(with: $0.element, at: $0.offset, animated: false)
      })
    rhythmSegment.selectedSegmentIndex = 0

    // Add mode
    if props.rhythmData == nil {
      rhythmStack.addArrangedSubview(rhythmSegment)
    }

    rhythmStack.addArrangedSubview(durationStack)
    rhythmStack.spacing = 8
    stackView.spacing = 4
    stackView.axis = .vertical
    stackView.addArrangedSubview(rhythmStack)
    stackView.addArrangedSubview(modifierSegment)
  }

  @IBAction func didEditCell(sender: UIButton) {
    guard let durationType = RBDurationType(rawValue: sender.tag),
      let modifierType = RBModifierType(rawValue: modifierSegment.selectedSegmentIndex),
      let rhythmType = RBRhythmType(rawValue: rhythmSegment.selectedSegmentIndex)
      else { return }
    let value = durationType.value * modifierType.value

    // Edit selected cell
    if let data = props.rhythmData {
      data.duration = value
      props.didUpdateRhythmCallback?(data)
    } else { // Add Cell
      switch rhythmType {
      case .note:
        let data = RBRhythmData(duration: value)
        props.didAddRhythmCallback?(data)
      case .rest:
        props.didAddRestCallback?(value)
      }
    }
  }
}

final class RhythmToolbarMode: RBToolbarMode {
  typealias PropType = RhythmToolbarModeProps
  var props = RhythmToolbarModeProps()
  var toolbarTitle: String = "Rhythm"

  var view: RBToolbarModeView<RhythmToolbarModeProps> {
    return RhythmToolbarModeView(props: props)
  }
}
