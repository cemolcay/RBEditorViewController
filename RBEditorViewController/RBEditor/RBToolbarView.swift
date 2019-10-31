//
//  RBToolbarView.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

protocol RBToolbarModeProps: class {
  init()
}

protocol RBToolbarMode: class {
  associatedtype PropType: RBToolbarModeProps
  var toolbarTitle: String { get set }
  var props: PropType { get set }
  var view: RBToolbarModeView<PropType> { get }
  init()
}

extension RBToolbarMode {
  init(props: PropType) {
    self.init()
    self.props = props
  }
}

class RBToolbarModeView<T: RBToolbarModeProps>: UIView {
  let scrollView = UIScrollView()
  let stackView = UIStackView()
  var props: T

  init(props: T) {
    self.props = props
    super.init(frame: .zero)
    commonInit()
  }

  required init?(coder: NSCoder) {
    self.props = T()
    super.init(coder: coder)
    commonInit()
  }

  func commonInit() {
    addSubview(scrollView)
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true

    scrollView.addSubview(stackView)
    stackView.axis = .horizontal
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
    stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
    stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
    stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
    stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
  }

  func render() {}

  func selectCellAlert() {
    let label = UILabel()
    label.text = i18n.selectCell.description
    label.textAlignment = .center
    label.textColor = UIColor.toolbarButtonTextColor
    label.font = UIFont.toolbarButtonFont
    stackView.addArrangedSubview(label)
    stackView.alignment = .center
  }
}

class RBToolbarView: UIView {
  let layoutStack = UIStackView()
  let titleLabel = UILabel()
  let contentView = UIView()
  let borderLayer = CALayer()
  let borderSize: CGFloat = 0.5

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  func commonInit() {
    layer.addSublayer(borderLayer)
    borderLayer.backgroundColor = UIColor.toolbarBorderColor.cgColor

    addSubview(layoutStack)
    layoutStack.translatesAutoresizingMaskIntoConstraints = false
    layoutStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
    layoutStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
    layoutStack.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    layoutStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
    layoutStack.axis = .vertical
    layoutStack.spacing = 8

    layoutStack.addArrangedSubview(titleLabel)
    titleLabel.font = UIFont.toolbarTitleFont
    titleLabel.textColor = UIColor.toolbarTitleColor
    titleLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
    layoutStack.addArrangedSubview(contentView)
  }

  func render<T: RBToolbarMode>(mode: T) {
    // Clear content view.
    titleLabel.text = mode.toolbarTitle
    contentView.subviews.forEach({ $0.removeFromSuperview() })

    // Create toolbar view from mode.
    let toolbar = mode.view
    contentView.addSubview(toolbar)
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    toolbar.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
    toolbar.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
    toolbar.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    toolbar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    toolbar.render()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    borderLayer.frame = CGRect(
      x: 0,
      y: 0,
      width: frame.size.width,
      height: borderSize)
  }
}
