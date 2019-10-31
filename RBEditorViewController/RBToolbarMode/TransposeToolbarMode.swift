//
//  TransposeToolbarMode.swift
//  RhythmBud
//
//  Created by cem.olcay on 24/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class TransposeToolbarModeProps: RBToolbarModeProps {
  var rhythmData: RBRhythmData?
  var didUpdateTransposeCallback: ((Int) -> Void)?

  required init() {}

  init(
    rhythmData: RBRhythmData?,
    didUpdateTransposeCallback: ((Int) -> Void)?) {
    self.rhythmData = rhythmData
    self.didUpdateTransposeCallback = didUpdateTransposeCallback
  }
}

class TransposeToolbarModeView: RBToolbarModeView<TransposeToolbarModeProps> {
  let transposeLabel = UILabel()
  let transposeSlider = UISlider()

  override func render() {
    super.render()

    guard let data = props.rhythmData else { selectCellAlert(); return }

    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    stackView.spacing = 8
    stackView.addArrangedSubview(transposeLabel)
    stackView.addArrangedSubview(transposeSlider)

    transposeLabel.text = "\(Int(data.transpose))"
    transposeLabel.textColor = UIColor.toolbarButtonTextColor
    transposeLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true

    transposeSlider.tintColor = UIColor.toolbarButtonTextColor
    transposeSlider.minimumValue = -24
    transposeSlider.maximumValue = 24
    transposeSlider.value = Float(data.transpose)
    transposeSlider.addTarget(self, action: #selector(sliderDidUpdate(sender:)), for: .valueChanged)
  }

  @IBAction func sliderDidUpdate(sender: UISlider) {
    let value = Int(sender.value)
    props.rhythmData?.transpose = value
    transposeLabel.text = "\(value)"
    props.didUpdateTransposeCallback?(value)
  }
}

final class TransposeToolbarMode: RBToolbarMode {
  typealias PropType = TransposeToolbarModeProps
  var toolbarTitle: String = i18n.transpose.description
  var props = TransposeToolbarModeProps()

  var view: RBToolbarModeView<TransposeToolbarModeProps> {
    return TransposeToolbarModeView(props: props)
  }
}
