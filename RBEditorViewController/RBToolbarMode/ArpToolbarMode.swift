//
//  ArpToolbarMode.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class ArpToolbarModeProps: RBToolbarModeProps {
  var rhythmData: RBRhythmData?
  var didUpdateArpCallback: ((RBArp) -> Void)?

  required init() {}

  init(
    rhythmData: RBRhythmData?,
    didUpdateArpCallback: ((RBArp) -> Void)?) {
    self.rhythmData = rhythmData
    self.didUpdateArpCallback = didUpdateArpCallback
  }
}

class ArpToolbarModeView: RBToolbarModeView<ArpToolbarModeProps> {

  override func render() {
    super.render()
    guard let data = props.rhythmData else { selectCellAlert(); return }

    stackView.spacing = 16
    scrollView.contentInset.left += 8
    RBArp.allCases
      .map({ $0.toolbarButton() })
      .forEach({
        $0.addTarget(self, action: #selector(arpDidSelect(sender:)), for: .touchUpInside)
        $0.isSelected = $0.tag == data.arp.rawValue
        stackView.addArrangedSubview($0)
      })
  }

  @IBAction func arpDidSelect(sender: UIButton) {
    guard let arp = RBArp(rawValue: sender.tag) else { return }
    stackView.arrangedSubviews
      .enumerated()
      .forEach({ ($0.element as? UIButton)?.isSelected = $0.offset == sender.tag })
    props.rhythmData?.arp = arp
    props.didUpdateArpCallback?(arp)
  }
}

final class ArpToolbarMode: RBToolbarMode {
  typealias PropType = ArpToolbarModeProps
  var props = ArpToolbarModeProps()
  var toolbarTitle: String = i18n.editArp.description

  var view: RBToolbarModeView<ArpToolbarModeProps> {
    return ArpToolbarModeView(props: props)
  }
}
