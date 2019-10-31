//
//  RatchetToolbarMode.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class RatchetToolbarModeProps: RBToolbarModeProps {
  var rhythmData: RBRhythmData?
  var didUpdateRatchetCallback: ((RBRatchet) -> Void)?

  required init() {}

  init(
    rhythmData: RBRhythmData?,
    didUpdateRatchetCallback: ((RBRatchet) -> Void)?) {
    self.rhythmData = rhythmData
    self.didUpdateRatchetCallback = didUpdateRatchetCallback
  }
}

class RatchetToolbarModeView: RBToolbarModeView<RatchetToolbarModeProps> {
  override func render() {
    super.render()
    guard let data = props.rhythmData else { selectCellAlert(); return }

    stackView.spacing = 16
    scrollView.contentInset.left += 8
    RBRatchet.allCases
      .map({ $0.toolbarButton() })
      .forEach({
        $0.addTarget(self, action: #selector(ratchedDidPress(sender:)), for: .touchUpInside)
        $0.isSelected = $0.tag == data.ratchet.rawValue
        self.stackView.addArrangedSubview($0)
      })
  }

  @IBAction func ratchedDidPress(sender: UIButton) {
    guard let ratchet = RBRatchet(rawValue: sender.tag) else { return }
    stackView.arrangedSubviews
      .enumerated()
      .forEach({ ($0.element as? UIButton)?.isSelected = $0.offset == sender.tag })
    props.rhythmData?.ratchet = ratchet
    props.didUpdateRatchetCallback?(ratchet)
  }
}

final class RatchetToolbarMode: RBToolbarMode {
  typealias PropType = RatchetToolbarModeProps
  var props = RatchetToolbarModeProps()
  var toolbarTitle: String = i18n.editRatchet.description

  var view: RBToolbarModeView<RatchetToolbarModeProps> {
    return RatchetToolbarModeView(props: props)
  }
}
