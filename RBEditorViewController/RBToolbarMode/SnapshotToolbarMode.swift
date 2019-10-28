//
//  SnapshotToolbarMode.swift
//  RBEditorViewController
//
//  Created by cem.olcay on 15/10/2019.
//  Copyright © 2019 cemolcay. All rights reserved.
//

import UIKit

class SnapshotToolbarModeProps: RBToolbarModeProps {
  var snapshotData: RBSnapshotData
  var didPressAddButtonCallback: (() -> Void)?
  var didPressMIDICCButtonCallback: (() -> Void)?
  var didSelectSnapshotAtIndex: ((_ index: Int) -> Void)?

  required init() {
    snapshotData = RBSnapshotData()
  }

  init(
    snapshotData: RBSnapshotData,
    didPressAddButtonCallback: (() -> Void)?,
    didPressMIDICCButtonCallback: (() -> Void)?,
    didSelectSnapshotAtIndex: ((_ index: Int) -> Void)?) {
    self.snapshotData = snapshotData
    self.didPressAddButtonCallback = didPressAddButtonCallback
    self.didPressMIDICCButtonCallback = didPressMIDICCButtonCallback
    self.didSelectSnapshotAtIndex = didSelectSnapshotAtIndex
  }
}

class RBSnapshotCellView: UIView {
  var button = UIButton(type: .system)
  var image = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func commonInit() {
    addSubview(image)
    addSubview(button)

    image.image = nil
    button.setTitle(nil, for: .normal)

    image.translatesAutoresizingMaskIntoConstraints = false
    image.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    image.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    image.topAnchor.constraint(equalTo: topAnchor).isActive = true
    image.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    button.translatesAutoresizingMaskIntoConstraints = false
    button.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    button.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    button.topAnchor.constraint(equalTo: topAnchor).isActive = true
    button.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
}

class SnapshotToolbarModeView: RBToolbarModeView<SnapshotToolbarModeProps> {
  var addButton = UIButton(type: .system)
  var ccButton = UIButton(type: .system)
  var snapshotScroll = UIScrollView()
  var snapshotStack = UIStackView()

  override func render() {
    super.render()
    let snapshots = props.snapshotData

    addButton.setTitle("Add", for: .normal)
    addButton.addTarget(self, action: #selector(addButtonPressed(sender:)), for: .touchUpInside)

    ccButton.setTitle("CC#\(snapshots.cc)", for: .normal)
    ccButton.addTarget(self, action: #selector(ccButtonPressed(sender:)), for: .touchUpInside)

    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    scrollView.isScrollEnabled = false
    stackView.addArrangedSubview(addButton)
    stackView.addArrangedSubview(snapshotScroll)
    stackView.addArrangedSubview(ccButton)

    snapshotScroll.addSubview(snapshotStack)
    snapshotStack.axis = .horizontal
    snapshotStack.spacing = 8
    snapshotStack.translatesAutoresizingMaskIntoConstraints = false
    snapshotStack.leftAnchor.constraint(equalTo: snapshotScroll.leftAnchor).isActive = true
    snapshotStack.rightAnchor.constraint(equalTo: snapshotScroll.rightAnchor).isActive = true
    snapshotStack.topAnchor.constraint(equalTo: snapshotScroll.topAnchor).isActive = true
    snapshotStack.bottomAnchor.constraint(equalTo: snapshotScroll.bottomAnchor).isActive = true
    snapshotStack.heightAnchor.constraint(equalTo: snapshotScroll.heightAnchor).isActive = true

    for index in 0..<snapshots.snapshots.count {
      let cell = RBSnapshotCellView(frame: .zero)
      cell.translatesAutoresizingMaskIntoConstraints = false
      cell.layer.borderColor = UIColor.black.cgColor
      cell.layer.borderWidth = 1
      cell.button.tag = index
      cell.button.addTarget(self, action: #selector(snapshotSelected(sender:)), for: .touchUpInside)
      snapshotStack.addArrangedSubview(cell)
    }
  }

  @IBAction func addButtonPressed(sender: UIButton) {
    props.didPressAddButtonCallback?()
  }

  @IBAction func ccButtonPressed(sender: UIButton) {
    props.didPressMIDICCButtonCallback?()
  }

  @IBAction func snapshotSelected(sender: UIButton) {
    props.didSelectSnapshotAtIndex?(sender.tag)
  }
}

final class SnapshotToolbarMode: RBToolbarMode {
  typealias PropType = SnapshotToolbarModeProps
  var props = SnapshotToolbarModeProps()
  var toolbarTitle: String = "Snapshots"

  var view: RBToolbarModeView<SnapshotToolbarModeProps> {
    return SnapshotToolbarModeView(props: props)
  }
}
