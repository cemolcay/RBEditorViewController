//
//  StrumToolbarMode.swift
//  RhythmBud
//
//  Created by cem.olcay on 01/11/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class StrumToolbarModeProps: RBToolbarModeProps {
  var rhythmData: RBRhythmData?
  var didUpdateStrumCallback: ((RBStrum) -> Void)?

  required init() {}

  init(
    rhythmData: RBRhythmData?,
    didUpdateStrumCallback: ((RBStrum) -> Void)?) {
    self.rhythmData = rhythmData
    self.didUpdateStrumCallback = didUpdateStrumCallback
  }
}

class StrumToolbarModeView: RBToolbarModeView<StrumToolbarModeProps> {
  var offsetSlider = UISlider()
  var offsetLabel = UILabel()
  var orderSegment = UISegmentedControl()
  
  override func render() {
    super.render()

    guard let data = props.rhythmData else { selectCellAlert(); return }
    stackView.spacing = 8
    stackView.axis = .vertical

    let orderStack = UIStackView()
    orderStack.axis = .horizontal
    orderStack.distribution = .fill
    orderStack.alignment = .center
    orderStack.spacing = 8

    let orderLabel = UILabel()
    orderLabel.font = .toolbarButtonFont
    orderLabel.textColor = .toolbarButtonTextColor
    orderLabel.text = "\(i18n.strumOrder):"

    orderSegment.removeAllSegments()
    RBStrumOrder.allCases
      .map({ $0.description })
      .enumerated()
      .forEach({
        orderSegment.insertSegment(withTitle: $0.element, at: $0.offset, animated: false)
      })
    orderSegment.selectedSegmentIndex = data.strum.order.rawValue
    orderSegment.addTarget(self, action: #selector(segmentControlDidUpdate(sender:)), for: .valueChanged)

    if #available(iOS 13.0, *) {
      orderSegment.backgroundColor = UIColor.toolbarButtonSelectedBackgroundColor
      orderSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.segmentedControlSelectedTextColor], for: .selected)
      orderSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.segmentedControlTextColor], for: .normal)
    } else {
      orderSegment.tintColor = UIColor.white
    }

    orderStack.addArrangedSubview(orderLabel)
    orderStack.addArrangedSubview(orderSegment)

    let offsetStack = UIStackView()
    offsetStack.axis = .horizontal
    offsetStack.distribution = .fill
    offsetStack.alignment = .center
    offsetStack.spacing = 8

    offsetLabel.text = "\(Int(data.strum.offset * 100))%"
    offsetLabel.textColor = UIColor.toolbarButtonTextColor
    offsetLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

    offsetSlider.tintColor = UIColor.toolbarButtonTextColor
    offsetSlider.minimumValue = 0
    offsetSlider.maximumValue = 1
    offsetSlider.value = Float(data.strum.offset)
    offsetSlider.addTarget(self, action: #selector(sliderDidUpdate(sender:event:)), for: .valueChanged)

    offsetStack.addArrangedSubview(offsetLabel)
    offsetStack.addArrangedSubview(offsetSlider)

    stackView.distribution = .fillEqually
    stackView.addArrangedSubview(orderStack)
    stackView.addArrangedSubview(offsetStack)
  }

  @IBAction func segmentControlDidUpdate(sender: UISegmentedControl) {
    guard let order = RBStrumOrder(rawValue: sender.selectedSegmentIndex),
      let data = props.rhythmData
      else { return }
    data.strum.order = order
    props.didUpdateStrumCallback?(data.strum)
  }

  @IBAction func sliderDidUpdate(sender: UISlider, event: UIEvent) {
    let value = Double(sender.value)
    offsetLabel.text = "\(Int(sender.value * 100))%"

    if event.allTouches?.first?.phase == .some(.ended), let data = props.rhythmData {
      data.strum.offset = value
      props.didUpdateStrumCallback?(data.strum)
    }
  }
}

final class StrumToolbarMode: RBToolbarMode {
  typealias PropType = StrumToolbarModeProps
  var props = StrumToolbarModeProps()
  var toolbarTitle: String = i18n.strumToolbarTitle.description

  var view: RBToolbarModeView<StrumToolbarModeProps> {
    return StrumToolbarModeView(props: props)
  }
}
