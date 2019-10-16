//
//  RBActionView.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

protocol ToolbarButtoning: RawRepresentable, CustomStringConvertible {}

extension ToolbarButtoning where Self: RawRepresentable, Self.RawValue == Int  {
  func toolbarButton() -> UIButton {
    let but = UIButton(type: .system)
    but.setAttributedTitle(
      NSAttributedString(
        string: description,
        attributes: [.font: UIFont.systemFont(ofSize: 13)]),
      for: .normal)
    but.tag = rawValue
    return but
  }
}

protocol RBActionViewDelegate: class {
  func actionView(_ actionView: RBActionView, didSelect action: RBAction, sender: UIButton)
  func actionView(_ actionView: RBActionView, didSelect mode: RBMode, sender: UIButton)
}

class RBActionView: UIView {
  var scrollView = UIScrollView()
  var layoutStack = UIStackView()
  var actionStack = UIStackView()
  var modeStack = UIStackView()
  weak var delegate: RBActionViewDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func commonInit() {
    addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    scrollView.addSubview(layoutStack)
    layoutStack.translatesAutoresizingMaskIntoConstraints = false
    layoutStack.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
    layoutStack.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
    layoutStack.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
    layoutStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
    layoutStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    layoutStack.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor).isActive = true
    layoutStack.axis = .vertical

    actionStack.axis = .vertical
    RBAction.allCases
      .map({ $0.toolbarButton() })
      .forEach({
        $0.addTarget(self, action: #selector(actionButtonDidPress(sender:)), for: .touchUpInside)
        actionStack.addArrangedSubview($0)
      })

    modeStack.axis = .vertical
    modeStack.alignment = .center

    let modeTitleLabel = UILabel()
    modeTitleLabel.font = UIFont.systemFont(ofSize: 13)
    modeTitleLabel.text = "Mode"
    modeTitleLabel.textColor = .black
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

    selectMode(at: 0)
  }

  @IBAction func actionButtonDidPress(sender: UIButton) {
    guard let action = RBAction(rawValue: sender.tag) else { return }
    delegate?.actionView(self, didSelect: action, sender: sender)
  }

  @IBAction func modeButtonDidPress(sender: UIButton) {
    selectMode(at: sender.tag)
    guard let mode = RBMode(rawValue: sender.tag) else { return }
    delegate?.actionView(self, didSelect: mode, sender: sender)
  }

  func selectMode(at index: Int) {
    modeStack.arrangedSubviews.forEach({ ($0 as? UIButton)?.isSelected = $0.tag == index })
  }
}
