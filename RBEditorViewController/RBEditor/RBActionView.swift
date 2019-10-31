//
//  RBActionView.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

protocol RBActionViewDelegate: class {
  func actionView(_ actionView: RBActionView, didSelect action: RBAction, sender: UIButton)
  func actionView(_ actionView: RBActionView, didSelect mode: RBMode, sender: UIButton)
}

class RBActionView: UIView {
  var scrollView = UIScrollView()
  var layoutStack = UIStackView()
  var actionStack = UIStackView()
  var modeStack = UIStackView()
  let borderLayer = CALayer()
  let borderSize: CGFloat = 0.5
  weak var delegate: RBActionViewDelegate?

  // MARK: Init

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func commonInit() {
    layer.addSublayer(borderLayer)
    borderLayer.backgroundColor = UIColor.actionBarBorderColor.cgColor

    addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

    scrollView.addSubview(layoutStack)
    layoutStack.translatesAutoresizingMaskIntoConstraints = false
    layoutStack.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
    layoutStack.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
    layoutStack.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
    layoutStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
    layoutStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    layoutStack.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor).isActive = true
    layoutStack.axis = .vertical
    layoutStack.spacing = 8

    actionStack.axis = .vertical
    let actionButtons = RBAction.allCases.map({ $0.actionButton })
    actionButtons.forEach({ $0.addTarget(self, action: #selector(actionButtonDidPress(sender:)), for: .touchUpInside) })

    let topRow = UIStackView()
    topRow.axis = .horizontal
    topRow.distribution = .fillEqually
    topRow.alignment = .fill
    topRow.addArrangedSubview(actionButtons[0])
    topRow.addArrangedSubview(actionButtons[1])
    actionStack.addArrangedSubview(topRow)

    let bottomRow = UIStackView()
    bottomRow.axis = .horizontal
    bottomRow.distribution = .fillEqually
    bottomRow.alignment = .fill
    bottomRow.addArrangedSubview(actionButtons[2])
    bottomRow.addArrangedSubview(actionButtons[3])
    actionStack.addArrangedSubview(bottomRow)

    modeStack.axis = .vertical
    modeStack.alignment = .center
    modeStack.spacing = 4

    let modeTitleLabel = UILabel()
    modeTitleLabel.font = UIFont.actionBarTitleFont
    modeTitleLabel.text = i18n.mode.description
    modeTitleLabel.textColor = UIColor.actionBarTitleColor
    modeStack.addArrangedSubview(modeTitleLabel)

    RBMode.allCases
      .map({ $0.toolbarButton() })
      .forEach({
        $0.addTarget(self, action: #selector(modeButtonDidPress(sender:)), for: .touchUpInside)
        modeStack.addArrangedSubview($0)
      })

    let actionContainer = UIStackView()
    actionContainer.axis = .horizontal
    actionContainer.alignment = .top
    actionContainer.addArrangedSubview(actionStack)
    let modeContainer = UIStackView()
    modeContainer.axis = .horizontal
    modeContainer.alignment = .bottom
    modeContainer.addArrangedSubview(modeStack)

    let spacing = UIView()
    spacing.translatesAutoresizingMaskIntoConstraints = false
    spacing.setContentHuggingPriority(.defaultHigh, for: .vertical)
    spacing.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

    layoutStack.addArrangedSubview(actionContainer)
    layoutStack.addArrangedSubview(spacing)
    layoutStack.addArrangedSubview(modeContainer)

    selectMode(mode: .rhythm)
  }

  // MARK: Lifecycle

  override func layoutSubviews() {
    super.layoutSubviews()
    borderLayer.frame = CGRect(
      x: frame.size.width - borderSize,
      y: 0,
      width: borderSize,
      height: frame.size.height)
  }

  // MARK: Actions

  @IBAction func actionButtonDidPress(sender: UIButton) {
    guard let action = RBAction(rawValue: sender.tag) else { return }
    delegate?.actionView(self, didSelect: action, sender: sender)
  }

  @IBAction func modeButtonDidPress(sender: UIButton) {
    guard let mode = RBMode(rawValue: sender.tag) else { return }
    selectMode(mode: mode)
  }

  func selectMode(mode: RBMode) {
    guard let sender = getModeButton(for: mode) else { return }
    modeStack.arrangedSubviews.forEach({ ($0 as? UIButton)?.isSelected = $0.tag == mode.rawValue })
    delegate?.actionView(self, didSelect: mode, sender: sender)
  }

  // MARK: Utils

  func getActionButton(for action: RBAction) -> UIButton? {
    let buttons = actionStack.arrangedSubviews[0].subviews + actionStack.arrangedSubviews[1].subviews
    return buttons.filter({ $0 is UIButton && $0.tag == action.rawValue }).first as? UIButton
  }

  func getModeButton(for mode: RBMode) -> UIButton? {
    return modeStack.subviews.filter({ $0 is UIButton && $0.tag == mode.rawValue }).first as? UIButton
  }
}
