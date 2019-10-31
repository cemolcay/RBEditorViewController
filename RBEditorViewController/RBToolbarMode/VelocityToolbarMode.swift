//
//  VelocityToolbarMode.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class VelocityToolbarModeProps: RBToolbarModeProps {
  var rhythmData: RBRhythmData?
  var didUpdateVelocityCallback: ((_ velocity: Int, _ globally: Bool) -> Void)?

  required init() {}

  init(
    rhythmData: RBRhythmData?,
    didUpdateVelocityCallback: ((Int, Bool) -> Void)?) {
    self.rhythmData = rhythmData
    self.didUpdateVelocityCallback = didUpdateVelocityCallback
  }
}

class VelocityToolbarModeView: RBToolbarModeView<VelocityToolbarModeProps> {
  var globalButton = UIButton(type: .system)
  var velocityLabel = UILabel()

  override func render() {
    super.render()
    guard let data = props.rhythmData else { selectCellAlert(); return }

    globalButton.setTitle(i18n.global.description, for: .normal)
    globalButton.setTitleColor(UIColor.toolbarButtonTextColor, for: .normal)
    globalButton.setTitleColor(UIColor.toolbarButtonSelectedTextColor, for: .selected)
    globalButton.tintColor = UIColor.toolbarButtonSelectedBackgroundColor
    globalButton.addTarget(self, action: #selector(globalButtonPressed(sender:)), for: .touchUpInside)

    velocityLabel.text = "\(data.velocity)"
    velocityLabel.textColor = UIColor.toolbarButtonTextColor
    velocityLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
    
    let slider = UISlider(frame: .zero)
    slider.addTarget(self, action: #selector(velocitySliderDidChange(sender:)), for: .valueChanged)
    slider.tintColor = UIColor.toolbarButtonTextColor
    slider.minimumValue = 0
    slider.maximumValue = 127
    slider.value = Float(data.velocity)

    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    stackView.spacing = 8
    scrollView.isScrollEnabled = false
    stackView.addArrangedSubview(globalButton)
    stackView.addArrangedSubview(velocityLabel)
    stackView.addArrangedSubview(slider)
  }

  @IBAction func globalButtonPressed(sender: UIButton) {
    globalButton.isSelected = !globalButton.isSelected
  }

  @IBAction func velocitySliderDidChange(sender: UISlider) {
    let value = Int(sender.value)
    velocityLabel.text = "\(value)"
    props.rhythmData?.velocity = value
    props.didUpdateVelocityCallback?(value, globalButton.isSelected)
  }
}

final class VelocityToolbarMode: RBToolbarMode {
  typealias PropType = VelocityToolbarModeProps
  var props = VelocityToolbarModeProps()
  var toolbarTitle: String = i18n.editVelocity.description

  var view: RBToolbarModeView<VelocityToolbarModeProps> {
    return VelocityToolbarModeView(props: props)
  }
}
